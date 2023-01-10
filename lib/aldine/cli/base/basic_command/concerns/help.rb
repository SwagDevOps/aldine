# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../concerns'

# Help related concern.
#
# @see https://github.com/mdub/clamp/blob/2bea3050d83d0d6207cff593e58ee4450cf1f8df/lib/clamp/help.rb#L42
module Aldine::Cli::Base::BasicCommand::Concerns::Help
  protected

  # Get the render used to render help builder.
  #
  # @return [Proc]
  def help_renderer
    # @type [Clamp::Help::Builder] help
    lambda do |help|
      help.string
    end
  end

  # Prepare help with the common base.
  #
  # @param [String] invocation_path
  # @param [Clamp::Help::Builder, nil] builder
  # @yieldparam [Clamp::Help::Builder] help
  #
  # @return [Object]
  def with_help(invocation_path, builder = nil, &block)
    (builder || ::Clamp::Help::Builder.new).then do |help|
      help_builders.each_value { |f| f.call(help, invocation_path) }

      block&.call(help, invocation_path)
    end
  end

  # Get builders applied on help builder.
  #
  # @see https://github.com/mdub/clamp/blob/2bea3050d83d0d6207cff593e58ee4450cf1f8df/lib/clamp/help.rb#L42
  #
  # @return [Hash{Symbol => Proc}]
  def help_builders
    [
      :usage,
      :description,
      :parameters_heading,
      :subcommands_heading,
      :options_heading,
    ].map { |k| [k, self.__send__("help_#{k}_builder")] }.to_h
  end

  # @return [Proc]
  def help_usage_builder
    # @type [Clamp::Help::Builder] help
    # @type [String] invocation_path
    lambda do |help, invocation_path|
      help.add_usage(invocation_path, usage_descriptions)
    end
  end

  # @return [Proc]
  def help_description_builder
    # @type [Clamp::Help::Builder] help
    lambda do |help, _|
      help.add_description(description)
    end
  end

  # @return [Proc]
  def help_parameters_heading_builder
    lambda do |help, _|
      # @type [Clamp::Help::Builder] help
      return unless has_parameters?

      help.add_list(::Clamp.message(:parameters_heading), parameters)
    end
  end

  # @return [Proc]
  def help_subcommands_heading_builder
    # @type [Clamp::Help::Builder] help
    lambda do |help, _|
      return unless has_subcommands?

      help.add_list(::Clamp.message(:subcommands_heading), recognised_subcommands)
    end
  end

  # @return [Proc]
  def help_options_heading_builder
    # @type [Clamp::Help::Builder] help
    lambda do |help, _|
      help.add_list(Clamp.message(:options_heading), recognised_options)
    end
  end
end
