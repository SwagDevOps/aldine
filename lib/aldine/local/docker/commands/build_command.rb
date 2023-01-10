# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../commands'

# Describe ``build`` command for container.
class Aldine::Local::Docker::Commands::BuildCommand < Aldine::Local::Docker::Commands::BaseCommand
  autoload(:Pathname, 'pathname')
  autoload(:YAML, 'yaml')

  # @api private
  BUILD_PATH = Aldine::Local::RESOURCES_DIR.join('docker').freeze

  # @api private
  BUILD_FILE = 'Dockerfile'

  # @param [String] image
  # @param [String, nil] path
  def initialize(image:, path: nil)
    super.tap do
      self.image = image
      self.path = shell.pwd.join(path || self.configured_path)
    end.freeze
  end

  def to_a
    super
      .concat(['build', '-t', image])
      .concat(build_args.map { |k, v| ['--build-arg', "#{k}=#{v}"] }.flatten)
      .concat([build_path.relative_path_from(shell.pwd).to_path])
  end

  protected

  # @type [String]
  attr_accessor :image

  # Path from where image is built.
  #
  # @type [Pathname]
  # @return [Pathname]
  attr_accessor :path

  # Providers used to generate command build-args.
  #
  # @return [Array<Proc>]
  def build_args_providers
    [
      -> { settings.get('container.build.args') },
      lambda do
        settings.get('directories')&.dup.then do |directories|
          directories.transform_keys { |k| "#{k}_dir".to_sym }
        end
      end,
    ]
  end

  # @return [String]
  def configured_path
    settings.get('container.build.path').then do |v|
      v.to_s.empty? ? BUILD_PATH : v
    end
  end

  # @return [Pathname]
  def build_path
    (self.path.directory? ? self.path : BUILD_PATH).then do |v|
      dockerfile? ? v : BUILD_PATH
    end
  end

  # @return [Boolean]
  def dockerfile?
    true.tap do
      [
        -> { self.path.directory? },
        -> { self.path.join(BUILD_FILE).file? },
        -> { self.path.join(BUILD_FILE).readable? },
      ].each do |f|
        return false unless f.call
      end
    end
  end

  # Prepare build-args passed to the build command (keeping only defined args).
  #
  # @see #defined_args
  # @see #build_args_providers
  #
  # @return [Hash{Symbol => Object}]
  def build_args
    self.defined_args.then do |kept_args|
      build_args_providers.map do |func|
        # @type [Array<Symbol>]
        args = func.call

        args.dup.keep_if { |arg| kept_args.include?(arg) }
      end.then { |rows| Hash[*rows.map(&:to_a).flatten] }.to_h
    end
  end

  # Get original build-args declared from Dockerfile.
  #
  # @return [Array<Symbol>]
  def defined_args
    rule = /^ARG\s+(?<key>[[:alpha:]]+(?:_|[[:alpha:]]|[0-9])*)=(?<val>.*)$/i
    file = self.build_path.join(BUILD_FILE)

    file.read.lines.keep_if { |line| line.match?(rule) }.map do |line|
      line.match(rule).then { |matches| matches[:key] }
    end.map(&:to_sym)
  end
end
