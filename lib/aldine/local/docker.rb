# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../local'

# Local to docker communication methods.
module Aldine::Local::Docker
  autoload(:Pathname, 'pathname')

  __FILE__.gsub(/\.rb$/, '').tap do |path|
    {
      Command: :command,
      EnvFile: :env_file,
      ImageNamer: :image_namer,
      RakeRunner: :rake_runner,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end

  class << self
    include(::Aldine::Concerns::SettingsAware)

    # Get current UNIX user.
    #
    # @see https://ruby-doc.org/stdlib-2.5.3/libdoc/etc/rdoc/Etc.html#method-c-getpwnam
    #
    # @return [Struct]
    def user
      shell.user
    end

    # Get image name.
    #
    # @return [String]
    def image
      ImageNamer.new(user: user).call
    end

    # Get list of directories used by docker.
    #
    # @return [Array<String>]
    def directories
      %w[out src tmp] # tex directories
        .concat(%w[pack conf home].map { |dir| ".tmp/.sys/bundle/#{dir}" }) # bundle vendoring + config + home
        .sort
        .freeze
    end

    # Build docker image.
    #
    # @return [Process::Status]
    def build
      shell.sh('/usr/bin/env', 'docker', 'build', '-t', image, './docker')
    end

    # Executes given command in a container.
    #
    # @param [Array<String>] command
    # @param [String, nil] path
    # @param [Struct, nil] user
    #
    # @return [Process::Status]
    def run(command = [], path: nil, user: nil)
      around_execute do
        execute(command, path: path, user: user || self.user)
      end
    end

    # Install dependencies.
    #
    # @return [Process::Status]
    def install
      run(%w[bundle install --standalone])
    end

    # Execute given task with rake (in given path if any).
    #
    # @return [Process::Status]
    def rake(task, path: nil)
      around_execute do
        rake_runner.call(task.to_s, path: path)
      end
    end

    protected

    # Wrap (and prepare) docker execution.
    #
    # @return [Process::Status]
    def around_execute(&execute_stt)
      fs(silent: true).then do |fs|
        directories.each { |dir| fs.mkdir_p(dir) }

        fs.cp(bundle_config.realpath, tmpdir.local.realpath.join('.sys/bundle/conf'))
        fs.rm_rf(tmpdir.local.join('.sys/bundle/home/config')) # ensure config is not present in home
      end.then { execute_stt.call }
    end

    # Executes given command in a container.
    #
    # @param [Array<String>] command
    # @param [String, nil] path
    # @param [Struct] user
    #
    # @return [Process::Status]
    def execute(command = [], user:, path: nil, exception: true, silent: false)
      command_for(user: user, path: path)
        .to_a
        .concat(command)
        .then { |params| shell.sh(*params, exception: exception, silent: silent) }
    end

    # @param [String, nil] path
    # @param [Struct] user
    #
    # @return [Command]
    def command_for(user:, path: nil)
      Command.new(image: image, env_file: env_file, user: user, tmpdir: tmpdir, workdir: workdir, path: path)
    end

    # Get workdir used inside docker container.
    #
    # @return [Pathname]
    def workdir
      Pathname.new(env_file.fetch('WORKDIR'))
    end

    # Get an object representation of the ``tmpdir`` with local and remote paths.
    #
    # @return [Struct]
    def tmpdir
      {
        local: shell.pwd.expand_path.join('.tmp'),
        remote: Pathname.new("/tmp/u#{user.uid}"),
      }.then { |paths| Struct.new(*paths.keys, keyword_init: true).new(**paths) }
    end

    # @return [Module<::FileUtils>, Module<::FileUtils::Verbose>]
    def fs(**kwargs)
      shell.fs(**kwargs)
    end

    # @return [Module<::Aldine::Local::Shell>]
    def shell
      ::Aldine::Local::Shell
    end

    # @return [Module<::Aldine::Local::Tex>]
    def tex
      ::Aldine::Local::Tex
    end

    # @return [::Aldine::Local::Docker::EnvFile]
    def env_file
      ::Aldine.dotenv.then do
        {
          BUNDLE_USER_HOME: '/tmp/bundle',
          TERM: ENV.fetch('TERM', 'xterm'),
          TMPDIR: tmpdir.remote,
          WORKDIR: settings.get('container.workdir'),
        }.then do |defaults|
          ::Aldine::Local::Docker::EnvFile.new(defaults: defaults)
        end
      end
    end

    # @see #rake()
    #
    # @return [::Aldine::Local::Docker::RakeRunner]
    def rake_runner
      lambda do |command, **options|
        self.execute(command, **{
          user: self.user
        }.merge(options))
      end.then do |runner|
        ::Aldine::Local::Docker::RakeRunner.new(runner)
      end
    end

    # @return [::Aldine::Utils::BundleConfig]
    def bundle_config
      ::Aldine::Utils::BundleConfig.new(shell.pwd)
    end
  end
end
