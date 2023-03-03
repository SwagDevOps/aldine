# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Base for templated command.
#
# @abstract
class Aldine::Cli::Base::ErbCommand < Aldine::Cli::Base::BaseCommand
  autoload(:Pathname, 'pathname')
  autoload(:Rouge, 'rouge')

  "#{__dir__}/erb_command".tap do |path|
    {
      Output: :output,
      OutputType: :output_type,
      Rouge: :rouge,
      Template: :template,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end

  class << self
    protected

    def overridables
      {
        debug: nil,
        output: :param_output,
        tags: :param_tags,
        line_no: :param_line_no,
      }
    end

    # rubocop:disable Metrics/MethodLength

    def inherited(subclass)
      super(subclass) do
        subclass.class_eval do
          parameter('SOURCE', 'source file (or directory)', { attribute_name: :param_source })
          option('--[no-]debug', :flag, 'enable debug messages', { default: true })
          option('--line-no', 'LINE_NO', 'use with \the\inputlineno', { attribute_name: :param_line_no })
          option('--tags', 'TAGS', 'tags (comma separated tags)', { attribute_name: :param_tags })
          option(%w[-O --output], 'OUTPUT',
                 "output type {#{OutputType.types.join('|')}}",
                 {
                   default: OutputType.default.to_s,
                   attribute_name: :param_output
                 })
        end
      end
    end

    # rubocop:enable Metrics/MethodLength
  end

  # @!method debug?
  #   Denotes debug is active
  #   @return [Boolean]

  # @!attribute [r] param_output
  #   @return [String]

  # @!attribute [r] param_tags
  #   @return [String]

  # @!attribute [r] param_line_no
  #   @return [String, Integer, nil]

  # Get variables.
  #
  # @abstract
  #
  # @return [Hash{Symbol => Object}]
  def variables
    {}.merge(variables_builder&.call || {})
  end

  # Get file (or directory) given to be processed.
  #
  # @return [Pathname]
  def source
    # noinspection RubyResolve
    @param_source.then do |fp|
      raise '@param_source must be set' if [nil, ''].include?(fp)

      Pathname.new(fp)
    end
  end

  def execute
    output_type = OutputType.new(param_output)

    render.chomp.tap do |content|
      unless output_type.disabled?
        rouge.call(content) if output_type.term?
        output.call(content) if output_type.file?
      end
    end
  end

  # Render template.
  #
  # @return [String]
  def render
    template.call(variables)
  end

  protected

  # Generates variables at runtime.
  #
  # @return [Proc, nil]
  def variables_builder
    nil
  end

  def rouge
    Rouge.new
  end

  # @return [Integer, nil]
  def line_no
    self.param_line_no.then do |v|
      v.nil? ? nil : v.to_i
    end.then do |v|
      v and v >= 0 ? v : nil
    end
  end

  # Instance responsible to output a file result.
  #
  # @return [Output]
  def output
    Output.new(output_basepath, template_name, line_no: line_no, tags: output_tags, verbose: debug?)
  end

  # @return [Array<String>]
  def output_tags
    (self.param_tags || '')
      .split(/,\s*/)
      .reject { |v| ['', nil].include?(v) }
      .freeze
  end

  # Path used to output file (almost a filepath).
  #
  # @abstract
  #
  # @return [String]
  def output_basepath
    raise NotImplementedError
  end

  # Instance responsible to template generated variables.
  #
  # @return [Template]
  def template
    Template.new(template_name, debug: debug?)
  end

  # Get the name (without extension) for the template.
  #
  # @return [String]
  def template_name
    self.class.name.then do |class_name|
      raise RuntimeError, 'Can not get class name' unless class_name

      class_name.split('::').last.gsub(/(.)([A-Z])/, '\1_\2').downcase.gsub(/_command$/, '')
    end
  end
end
