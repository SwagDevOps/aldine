# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../settings'

# Extract values from environment as a structured representation.
class Aldine::Settings::Parser
  autoload(:YAML, 'yaml')

  # @param [String] root namespace - root for the keys
  # @param [Hash{String => Object}] payload
  def initialize(root, payload)
    self.root = root
    self.payload = payload
  end

  # @return [Hash{Symbol => Object}]
  def call(&block)
    ::Aldine::Settings::Parsed.new.tap do |result|
      self.payload.each do |k, value|
        next unless matcher.match(k)

        k.gsub(matcher, '').split('__').map(&:downcase).then do |segments|
          self.apply(result, segments, value) unless segments.empty?
        end
      end
    end.tap { |result| block&.call(result) }
  end

  protected

  # @type [String]
  attr_accessor :root

  # @type [Hash{String => String}]
  attr_accessor :payload

  def matcher
    /^#{Regexp.quote(root)}__/
  end

  # Apply given value nested with given (path) segments.
  #
  # @param [Hash] result
  # @param [Array<String>] path
  # @param [String] value
  #
  # @return [Hash{Symbol => Object}]
  def apply(result, path, value)
    # rubocop:disable Lint/UselessAssignment
    # noinspection RubyUnusedLocalVariable
    value = value.is_a?(String) ? yaml_load(value) : value
    # rubocop:enable Lint/UselessAssignment

    result.tap do
      return result if path.empty?

      path.map { |v| "[:#{v}]" }.join.then do |s|
        self.instance_eval("result#{s} = value", __FILE__, __LINE__)
      end
    end
  end

  # @param [String] value
  #
  # @return [Object]
  def yaml_load(value)
    YAML.safe_load(value)
  end
end
