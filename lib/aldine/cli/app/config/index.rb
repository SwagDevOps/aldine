# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../config'

# Represent configurations indexed by names, with dot-notation access.
class Aldine::Cli::App::Config::Index
  include(::Aldine::Concerns::Freezable)

  # @param [Hash, Array] values
  def initialize(values = {})
    @payload = make_payload(values)
    deep_freeze
  end

  # @param [String, Symbol] key
  #
  # @return [Object, self]
  def [](key)
    self.get(key) { nil }
  end

  # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity

  # Access the payload with a dot-notation.
  #
  # @param [String, Symbol] path
  #
  # @return [Object, self]
  def get(path, default = nil, &block)
    lambda do
      split(path).map { |v| "[#{v.inspect}]" }.join.then do |s|
        # noinspection RubyResolve
        self.instance_eval("self.payload#{s}", __FILE__, __LINE__)
      end
    rescue ::FrozenError
      raise KeyError, "key not found: #{path.inspect}" if default.nil? and block.nil?
    end.call.then do |result|
      result || default || block&.call
    end.then { |v| v.is_a?(::Hash) ? self.class.new(v) : v }
  end

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

  # @return [Hash{String => Object}]
  def to_h
    self.payload.to_h
  end

  def inspect
    self.payload.inspect
  end

  protected

  # @return [Hash]
  attr_reader :payload

  # @param [Hash, Array] values
  #
  # @return [Hash{String => Object}]
  def make_payload(values)
    Hash.new { |h, k| h[k] = h.dup.clear }.tap do |payload|
      values.to_h.each { |k, v| payload[k] = v }
    end
  end

  # Split given path.
  #
  # @param [String, Symbol] path
  #
  # @return [Array<String>]
  def split(path)
    (path.is_a?(Symbol) ? path.to_s : path).downcase.split('.')
  end
end
