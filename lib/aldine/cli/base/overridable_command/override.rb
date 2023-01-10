# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../overridable_command'

# Override intended to be appliable on a command.
class Aldine::Cli::Base::OverridableCommand::Override
  # @param [Class<Aldine::Cli::Base::OverridableCommand>] origin_class
  # @param [Hash{Symbol, String => Symbol, String, nil}, nil] definition
  def initialize(origin_class, definition, key: nil)
    self.origin_class = origin_class
    self.definition = (definition || {}).map { |k, v| [k.to_sym, (v || k).to_sym] }.to_h
    self.key = key || :override
  end

  # Ensure mapping for the override option.
  #
  # @api private
  # @return [Hash{Symbol => Symbol}]
  def mapping
    self.origin_instance.then do |instance|
      self.definition
          .to_h
          .transform_keys(&:to_sym)
          .map { |k, v| [k, v || k].map(&:to_sym) } # nil will be replaced by the key value
          .keep_if { |k, _| k != self.key } # avoid to alter override option itself
          .keep_if { |_, v| instance.respond_to?("#{v}=", true) } # ensure attribute exists
          .to_h
    end
  end

  # @param [Aldine::Cli::Base::OverridableCommand] command
  # @param [Hash{Symbol, String => Object}] override
  #
  # @return [Aldine::Cli::Base::OverridableCommand]
  def apply(command, override)
    command.tap do
      self.mapping.then do |mapping|
        override.each do |attribute, value|
          self.override_apply(command, attribute.to_s, value, mapping: mapping)
        end
      end
    end
  end

  protected

  # @return [Symbol]
  attr_accessor :key

  # @return [Hash{Symbol => Symbol}]
  attr_accessor :definition

  # @return [Class<Aldine::Cli::Base::OverridableCommand>]
  attr_accessor :origin_class

  # @return [Aldine::Cli::Base::OverridableCommand>]
  def origin_instance
    self.origin_class.allocate
  end

  # @param [String] attribute
  # @param [Object] value
  # @param [Hash{Symbol => Object}, nil] mapping
  #
  # @return [Boolean]
  def override_apply(command, attribute, value, mapping: nil)
    (mapping || self.mapping).fetch(attribute.to_sym, nil).then do |target|
      return false.tap { warn("#{attribute} is not defined as overridable") } if target.nil?

      "#{target}=".then do |callable|
        return true.tap { command.__send__(callable, value) }
      rescue StandardError
        return false.tap { warn("#{attribute} can not be overriden") }
      end
    end
  end
end
