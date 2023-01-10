# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Loader for commands.
#
# Commands SHOULD provide an identifier method to identify themself to the loader. Example:
#
# ```.ruby
# # This command should appear as my:awesomeness sub-command (and provide awesome features).
# class MyExtension::Cli::Commands::AwesomeNamedCommand
#   class << self
#     # @return [Symbol, String]
#     def identifier
#       'my:awesomeness'
#     end
#   end
# end
# ```
class Aldine::Cli::App::Loader
  autoload(:Pathname, 'pathname')
  {
    Parser: :parser,
  }.each { |k, v| autoload(k, "#{__dir__}/loader/#{v}") }

  # @return [Array<Pathname>]
  attr_reader :paths

  # Initialize with paths rom where subcommans are discovered and loaded.
  #
  # @param [Array<String, Pathname>] paths
  def initialize(paths)
    self.paths = paths.map { |path| Pathname.new(path).freeze }.freeze
  end

  # Process all available subcommands.
  #
  # Loadables are processed throuch given block.
  # Results of the given blocks are returned back.
  #
  # @return [Array]
  def call(&block)
    loadables.map do |name, loadable|
      block.call(name.to_s, loadable) if loadable
    end
  end

  protected

  # Paths where subcommands are retrieved.
  #
  # @type [Array<Pathname>]
  attr_writer :paths

  # Get subcommands files.
  #
  # @return [Array<Pathname>]
  def files
    paths
      .map { |path| path.glob('*_command.rb').sort }
      .flatten
      .keep_if { |fp| fp.file? and fp.readable? }
  end

  # Get loadables indexed by filepath.
  #
  # @return [Hash{String => Struct}]
  def loadables_mapping
    files
      .map { |fp| [fp, parse(fp)] }
      .map { |fp, loadable| [fp.to_s, info(loadable)] }
      .to_h.compact
  end

  # Get loadables indexed by name.
  #
  # @return [Hash{String => Struct}]
  def loadables
    {}.tap do |loadables|
      loadables_mapping.each_value do |loadable|
        loadable.name.to_sym.tap do |name|
          loadables[name] = loadable
        end
      end
    end
  end

  # Parse given file.
  #
  # @param [Pathname] file
  #
  # @return [Struct]
  def parse(file)
    Parser.parse(file)
  end

  # Give info for given loadable.
  #
  # Main goal is to restrict items seen from a loadable. As a result, only info
  # useful to setup a subcommand are kept.
  #
  # @param [Struct, nil] loadable
  #
  # @return [Struct]
  def info(loadable)
    return nil if [nil, ''].include?(loadable&.description)

    Struct.new(*%i[name description file loader], keyword_init: true)
          .new({
                 name: identify(loadable.loader.call) || name_for(loadable.file),
                 description: loadable.description.to_s,
                 file: loadable.file,
                 loader: loadable.loader,
               })
  end

  # Get a name (or identifier) for the given command-class.
  #
  # @param [Class] command_class
  #
  # @return [Symbol, nil]
  def identify(command_class)
    return nil unless command_class.respond_to?(:identifier)

    command_class.identifier.then do |identifier|
      [Symbol, String].include?(identifier.class) ? identifier.to_sym : nil
    end
  end

  # Make name for loaadable from given filepath.
  #
  # @param [Pathname] filepath
  #
  # @return [Symbol]
  def name_for(filepath)
    filepath
      .basename
      .to_s
      .gsub(/_command.rb$/, '')
      .gsub('_', '-')
      .to_sym
  end
end
