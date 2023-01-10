# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Overridable commands provide an ``override`` option
#
# ``override`` option is intended to override options or previous override(s) (merge strategy).
#
# @abstract
class Aldine::Cli::Base::OverridableCommand < Aldine::Cli::Base::BasicCommand
  "#{__dir__}/overridable_command".tap do |path|
    {
      Helper: :helper,
      Override: :override,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end

  def run(arguments)
    parse(arguments)
    override_with(self.override)
    execute
  end

  class << self
    # Denotes command is overridable.
    #
    # @return [Boolean]
    def overridable?
      !override.mapping.empty?
    end

    protected

    # Define mapping for the override option.
    #
    # @return [Hash{Symbol, String => Symbol, String, nil}, nil]
    def overridables
      {}
    end

    # @return [Override]
    def override
      Override.new(self, overridables)
    end
  end

  { attribute_name: :override, default: nil }.then do |options|
    option('--override', 'OVERRIDE', 'override', options) do |s|
      @override = (@override || {}).merge(YAML.safe_load("{#{s}}").to_h.transform_keys(&:to_sym))
    rescue StandardError => e
      {}.tap { warn(['error while parsing override option', e.message.lines.to_a[0]].compact.join(' - ')) }
    end
  end

  # Get defined override (option).
  #
  # @return [Hash{String => Object}]
  def override
    @override.then { |override| override.is_a?(Hash) ? override : nil }.to_h
  end

  # Override options (applying given override payload).
  #
  # @param [Hash{String => Object}] override
  #
  # @return [self]
  def override_with(override)
    self.tap do
      # @type [Override] override_applier
      self.class.__send__(:override)&.then do |override_applier|
        override_applier.apply(self, override)
      end
    end
  end

  class << self
    protected

    def help_renderer
      lambda do |help|
        override_helper.render_help(help, ovverride: self.overridable?)
      end
    end

    # @api private
    #
    # @return [Helper]
    def override_helper
      Helper.new(self, self.override)
    end

    # @return [Proc]
    def help_options_heading_builder
      lambda do |help, _|
        # @type [Array<Clamp::Option::Definition>] recognised_options
        override_helper.filter_recognised_options(recognised_options).then do |recognised_options|
          help.add_list(::Clamp.message(:options_heading), recognised_options)
        end
      end
    end
  end
end
