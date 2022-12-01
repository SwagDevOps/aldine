# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../aldine'

# Singleton access to settings extracted from the environment.
class Aldine::Settings
  "#{__dir__}/settings".then do |libdir|
    {
      Parsed: :parsed,
      Parser: :parser,
    }.each { |k, v| autoload(k, "#{libdir}/#{v}") }
  end

  # Access the payload with a dot-notation.
  #
  # @param [String, Symbol] path
  #
  # @return [Object]
  def get(path, default = nil)
    # noinspection RubyUnusedLocalVariable
    self.payload.then do |payload|
      split(path).map { |v| "[:#{v}]" }.join.then do |s|
        result = self.instance_eval("payload#{s}", __FILE__, __LINE__)
      rescue ::FrozenError
        raise KeyError, "key not found: #{path.inspect}"
      else
        return result || default
      end
    end
  end

  # @return [Hash{Symbol => Object}]
  def to_h
    self.payload
  end

  protected

  # @return [Hash{Symbol => Object}]
  attr_reader :payload

  # @param [Hash{String => String}, nil] payload
  def initialize(payload = nil)
    @payload = Parser.new(settings_namespace, payload || ENV.to_h).call(&:deep_freeze)
  end

  def settings_namespace
    'ALDINE'
  end

  # Split given path.
  #
  # @param [String, Symbol] path
  #
  # @return [Array<String>]
  def split(path)
    (path.is_a?(Symbol) ? path.to_s : path).downcase.split('.')
  end

  class << self
    def instance
      # @todo renew instance when env changes.
      self.instance = @instance || self.new
    end

    protected

    attr_writer :instance
  end
end
