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

  class << self
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
      "u#{user.uid}/texlive-#{tex.project_name}"
    end

    # Get list of directories used by docker.
    #
    # @return [Array<String>]
    def directories
      %w[out src tmp] # tex directories
        .concat(%w[pack conf].map { |dir| ".tmp/.sys/bundle/#{dir}" }) # bundle vendoring + config
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
      run(%w[bundle exec rake].concat([task.to_s]), path: path)
    end

    protected

    # Wrap (and prepare) docker execution.
    #
    # @return [Process::Status]
    def around_execute(&execute_stt)
      fs(silent: true).then do |fs|
        directories.each { |dir| fs.mkdir_p(dir) }

        fs.cp(bundle_config.realpath, tmpdir.local.realpath.join('.sys/bundle/conf'))
      end.then { execute_stt.call }
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

    # Executes given command in a container.
    #
    # @param [Array<String>] command
    # @param [String, nil] path
    # @param [Struct] user
    #
    # @return [Process::Status]
    def execute(command = [], user:, path: nil)
      [
        '/usr/bin/env', 'docker', 'run', '--rm',
        shell.tty? ? '-it' : nil,
        '-u', [user.uid, user.gid].join(':'),
        '-e', "TERM=#{ENV.fetch('TERM', 'xterm')}",
        '-e', "OUTPUT_NAME=#{tex.output_name}",
        '-e', "TMPDIR=#{tmpdir.remote}",
        '-v', "#{tmpdir.local.realpath}:#{tmpdir.remote}",
        '-v', "#{tmpdir.local.join('.sys/bundle/pack').realpath}:#{workdir.join(bundle_basedir)}",
        '-v', "#{tmpdir.local.join('.sys/bundle/conf').realpath}:#{workdir.join('.bundle')}",
        '-v', "#{shell.pwd.join('gems.rb').realpath}:#{workdir.join('gems.rb')}:ro",
        '-v', "#{shell.pwd.join('gems.locked').realpath}:#{workdir.join('gems.locked')}:ro",
        '-v', "#{shell.pwd.join('src').realpath}:#{workdir.join('src')}:ro",
        '-v', "#{shell.pwd.join('out').realpath}:#{workdir.join('out')}",
        '-v', "#{shell.pwd.join('tmp').realpath}:#{workdir.join('tmp')}",
        '-w', workdir.join(path.to_s).to_path,
        image
      ]
        .compact
        .concat(command)
        .then { |params| shell.sh(*params) }
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # Get workdir used inside docker container.
    #
    # @return [Pathname
    def workdir
      '/workdir'.then { |path| Pathname.new(path) }
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

    def shell
      ::Aldine::Local::Shell
    end

    def tex
      ::Aldine::Local::Tex
    end

    # @return [Aldine::Utils::BundleConfig]
    def bundle_config
      shell.pwd.then do |basedir|
        ::Aldine::Utils::BundleConfig.new(basedir)
      end
    end

    # @return [String]
    def bundle_basedir
      shell.pwd.then do |basedir|
        bundle_config.bundle_basedir.relative_path_from(basedir).to_path
      end
    end
  end
end
