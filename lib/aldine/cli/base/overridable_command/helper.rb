# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../overridable_command'

# Helper used to generate commands help.
#
# @see Aldine::Cli::Base::OverridableCommand.help
class Aldine::Cli::Base::OverridableCommand::Helper
  autoload(:YAML, 'yaml')

  # @param [Class<Aldine::Cli::Base::OverridableCommand>] origin_class
  # @param [Aldine::Cli::Base::OverridableCommand::Override] override
  def initialize(origin_class, override)
    @origin_class = origin_class
    @override = override
  end

  # @param [Clamp::Help::Builder] help
  # @param [Boolean] ovverride
  #
  # @return [String]
  def render_help(help, ovverride: true)
    [
      help.string,
      self.ovverride_help(displayable: ovverride)
    ].compact.join("\n")
  end

  # Get options filtered by visibility.
  #
  # @return [Array<::Clamp::Option::Definition>]
  def filter_recognised_options(recognised_options)
    {}.tap do |result|
      # @type [::Clamp::Option::Definition] option
      Array(recognised_options).reverse.each do |option|
        key = option.attribute_name.to_sym
        # rubocop:disable Style/SoleNestedConditional
        result[key] = option unless result.key?(key)
        if key == :override
          result[key] = nil unless origin_class.overridable?
        end
        # rubocop:enable Style/SoleNestedConditional
      end
    end.sort.to_h.compact.values
  end

  protected

  # @return [Class<Aldine::Cli::Base::OverridableCommand>]
  attr_reader :origin_class

  # @return [Aldine::Cli::Base::OverridableCommand::Override]
  attr_reader :override

  # Render the ``Override`` help section.
  #
  # @return [String, nil]
  # @see Aldine::Cli::Base::OverridableCommand.help
  def ovverride_help(displayable: true)
    return nil unless displayable

    "Override: #{override_yaml}"
  end

  # @param [Hash{Symbol, String => Object}] payload
  #
  # @return [String]
  def override_yaml(payload: nil, indent: nil)
    indent ||= ' ' * 4
    payload ||= override_payload

    YAML.dump(payload.transform_keys(&:to_s))
        .lines[1..-1]
        .map { |line| "#{indent}#{line.rstrip}" }
        .join(",\n")
        .then { |s| "{\n#{s}\n}" }
  end

  # Payload used to generate override help section.
  #
  # @return [Hash{Symbol => Object}]
  # @api private
  def override_payload
    override.mapping.sort.map do |key, value|
      # @type [Array<Clamp::Option::Definition>] recognised_options
      self.origin_class.__send__(:recognised_options).then do |recognised_options|
        recognised_options
          .keep_if { |option| option.attribute_name.to_sym == value }
          .last&.then { |option| [key, option.default_value] }
      end
    end.compact.to_h
  end
end
