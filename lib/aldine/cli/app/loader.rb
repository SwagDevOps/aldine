# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Loader for commands.
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
      info(loadable).then do |info|
        block.call(name.to_s, info) if info
      end
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

  # Get loadables indexed by names.
  #
  # @return [Hash{Symbol => Struct}]
  def loadables
    files.map { |fp| [name_for(fp), fp] }.to_h.map do |name, fp|
      parse(fp).then { |info| [name, info] }
    end.keep_if { |_, object| object }.to_h
  end

  # Parse given file.
  #
  # @param [Pathname] file
  #
  # @return [Array<YARD::CodeObjects::Base>]
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
    return nil if [nil, ''].include?(loadable.description)

    Struct.new(*%i[name description class_name], keyword_init: true)
          .new({
                 description: loadable.description.to_s,
                 class_name: loadable.loader.call,
               })
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
