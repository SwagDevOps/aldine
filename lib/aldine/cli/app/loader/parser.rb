# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../loader'

# Source-code parser based on YARD.
class Aldine::Cli::App::Loader::Parser
  autoload(:YARD, 'yard')

  # Initialize with parseable file.
  #
  # @param [Pathname] file
  def initialize(file)
    self.file = file

    @parsed_attributes = %i[file name namespace description loader].freeze
    # noinspection RubyLiteralArrayInspection
    @inheritance_whitlelist = [
      'Clamp::Command',
      'Aldine::Cli::Command',
      /^Aldine::Cli::Base::[A-Z]+/,
    ].freeze
  end

  class << self
    # Parse given file.
    #
    # @param [Pathname] file
    def parse(file)
      self.new(file).call
    end
  end

  def call
    parse_object.first&.then { |info| make(info) }
  end

  protected

  # Parsed file.
  #
  # @type [Pathname]
  attr_accessor :file

  # @return [Array<Symbol>]
  attr_reader :parsed_attributes

  # @todo Use config to retrieve the withelist.
  #
  # @return [Array<String, Regexp>]
  attr_reader :inheritance_whitlelist

  # @return [Array<YARD::CodeObjects::ClassObject>]
  def parse_object
    YARD.parse(file.to_path).then do
      registry.keep_if { |object| object.files.to_h.keys.include?(file.to_path) }
    end
  end

  # @return [Struct]
  def make(info)
    {
      file: file,
      name: info.name,
      namespace: info.namespace.to_s,
      description: (info.docstring&.lines || []).first,
      loader: make_loader(file, info)
    }.then { |kwargs| struct.new(**kwargs) }
  end

  # @return [Class<Struct>]
  def struct
    Struct.new(*parsed_attributes.sort, keyword_init: true)
  end

  # Get a registry of subcommands classes
  #
  # @return [Array<YARD::CodeObjects::ClassObject, YARD::CodeObjects::Base>]
  def registry
    YARD::Registry
      .all
      .keep_if { |object| object.is_a?(YARD::CodeObjects::ClassObject) }
      .keep_if { |object| inheritance_whitlelist?(object) }
      .reject { |object| object.has_tag?('abstract') }
  end

  # Provide a loader for given file with given info.
  #
  # @param [Pathname, String] file
  # @param [YARD::CodeObjects::ClassObject] info
  #
  # @return [Proc]
  def make_loader(file, info)
    [info.namespace, info.name].compact.join('::').then do |class_name|
      -> { load_class_file(file, class_name) }
    end
  end

  # Load given file and returns given class name.
  #
  # @param [String, Pathname] file
  # @param [String] class_name
  #
  # @return [Class]
  def load_class_file(file, class_name)
    "require('#{file}').then { #{class_name} }".then do |script|
      ::Object.class_eval(script, __FILE__, __LINE__ - 1)
    end
  end

  # Denotes given object is whitelisted on inheritance tree.
  #
  # @param [Array<YARD::CodeObjects::ClassObject, YARD::CodeObjects::Base>] object
  #
  # @return [Boolean]
  def inheritance_whitlelist?(object)
    object.inheritance_tree.map(&:to_s).then do |tree|
      inheritance_whitlelist.map do |pattern|
        if pattern.is_a?(Regexp)
          tree.map { |class_name| class_name.match?(pattern) }.include?(true)
        else
          tree.include?(pattern.to_s)
        end
      end
    end.include?(true)
  end
end
