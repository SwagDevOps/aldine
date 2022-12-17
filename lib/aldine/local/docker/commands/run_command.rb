# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../commands'

# Describe base ``run`` command for container.
class Aldine::Local::Docker::Commands::RunCommand < Aldine::Local::Docker::Commands::BaseCommand
  # rubocop:disable Metrics/ParameterLists

  # @param [String] image
  # @param [::Aldine::Local::Docker::EnvFile] env_file
  # @param [Struct] user
  # @param [Pathname] workdir
  # @param [Struct] tmpdir
  # @param [String, nil] path - path relative to workdir from where command will be run
  def initialize(image:, env_file:, user:, workdir:, tmpdir:, path:)
    super
    self.providers_init.then do
      self.image = image
      self.env_file = env_file
      self.user = user
      self.workdir = workdir
      self.tmpdir = tmpdir
      self.path = path
      self.command = []
    end
  end

  # rubocop:enable Metrics/ParameterLists

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

  def to_a
    super
      .concat(%w[run --rm])
      .concat(shell.tty? ? ['-it'] : [])
      .concat([
                '-u', [user.uid, user.gid].join(':'),
                '-e', "TERM=#{ENV.fetch('TERM', 'xterm')}",
                '-e', "TMPDIR=#{tmpdir.remote}",
                '-v', "#{tmpdir.local.realpath}:#{tmpdir.remote}",
                '-v', "#{bundle_dirs.fetch(:home).realpath}:#{env_file.fetch('BUNDLE_USER_HOME')}",
                '-v', "#{bundle_dirs.fetch(:pack).realpath}:#{workdir.join(bundle_basedir)}",
                '-v', "#{bundle_dirs.fetch(:conf).realpath}:#{workdir.join('.bundle')}",
                '-v', "#{shell.pwd.join('gems.rb').realpath}:#{workdir.join('gems.rb')}:ro",
                '-v', "#{bundle_dirs.fetch(:base).join('gems.locked').realpath}:#{workdir.join('gems.locked')}",
              ])
      .concat(volumes)
      .concat(vendorer.volume_for(shell.pwd, workdir))
      .concat(['-w', workdir.join(path.to_s).to_path])
      .concat(env_file.to_a)
      .concat([image])
      .concat(self.command)
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # @param [Array<String>] command
  #
  # @return [self]
  def concat(command)
    self.tap do
      self.command.push(*command)
    end
  end

  protected

  # @type [String]
  attr_accessor :image

  # @type [Struct]
  attr_accessor :user

  # @type [Struct]
  attr_accessor :tmpdir

  # @type [Pathname]
  attr_accessor :workdir

  # @type [String, nil] path
  attr_accessor :path

  # @type [::Aldine::Local::Docker::EnvFile]
  attr_accessor :env_file

  # Command executed in docker.
  #
  # @type [Array<String>]
  attr_accessor :command

  # @return [Class<::Aldine::Local::Docker::BundleTmpDirsProvider>]
  attr_accessor :bundle_tmp_dirs_provider

  # @return [Proc]
  attr_accessor :bundle_config_provider

  # @return [Proc]
  attr_accessor :vendorer_provider

  # @return [self]
  def providers_init
    self.tap do |instance|
      {
        bundle_tmp_dirs_provider: ::Aldine::Local::Docker::BundleTmpDirsProvider,
        bundle_config_provider: -> { ::Aldine::Utils::BundleConfig.new(shell.pwd) },
        vendorer_provider: -> { ::Aldine::Remote::Vendorer.new(shell.pwd) },
      }.each { |k, v| instance.__send__("#{k}=", v) }
    end
  end

  # Options for volumes (from directories settings).
  #
  # @return [Array<String>]
  def volumes
    settings
      .get('directories')
      .values
      .map { |directory| ['-v', "#{shell.pwd.join(directory).realpath}:#{workdir.join(directory)}"] }
      .flatten
  end

  # @return [::Aldine::Utils::BundleConfig]
  def bundle_config
    bundle_config_provider.call
  end

  # @return [String]
  def bundle_basedir
    shell.pwd.then do |basedir|
      bundle_config.bundle_basedir.relative_path_from(basedir).to_path
    end
  end

  # Get an instance of vendorer (with current path).
  #
  # @return [Aldine::Remote::Vendorer]
  def vendorer
    vendorer_provider.call
  end

  # Get directories used for bundle share and persistance.
  #
  # @return [Hash{Symbol => Pathname}]
  def bundle_dirs
    bundle_tmp_dirs_provider.call(tmpdir: tmpdir.local)
  end
end
