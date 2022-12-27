# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../aldine'

# Singleton access to settings extracted from the environment.
class Aldine::Settings
  autoload(:Digest, 'digest')
  autoload(:JSON, 'json')

  "#{__dir__}/settings".then do |libdir|
    {
      Parsed: :parsed,
      Parser: :parser,
    }.each { |k, v| autoload(k, "#{libdir}/#{v}") }
  end

  attr_reader :control

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

  # Set value on given path (on ENV), then settings have to be reloaded to reflect changes.
  #
  # @param [String, Symbol] path
  # @param [Object] value
  #
  # @return [Boolean] denote value has been set on source (``ENV``)
  def set(path, value)
    [settings_namespace].concat(split(path)).map(&:upcase).join('__').then do |key|
      YAML.dump(value).then do |v|
        self.source.nil? ? false : (self.source[key] = v).then { true }
      end
    end
  end

  # @return [Hash{Symbol => Object}]
  def to_h
    self.payload.dup
  end

  # Get an instance without write access.
  #
  # @return [self]
  def read_only
    self.clone.tap do |instance|
      instance.singleton_class.__send__(:protected, :set)
    end
  end

  protected

  # @return [Hash{Symbol => Object}]
  attr_reader :payload

  # @return [Class<ENV>, nil]
  attr_reader :source

  # @return [String]
  attr_writer :control

  # @param [Hash{String => String}, nil] payload
  # @param [Class<ENV>, nil] source
  def initialize(payload: nil, source: nil)
    payload ||= (source || self.class.__send__(:source)).to_h

    @source = source
    @control = self.class.__send__(:hexdigest, payload)
    @payload = Parser.new(settings_namespace, payload.to_h).call(&:deep_freeze)
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
    # @return [Aldine::Settings]
    def instance
      self.source.to_h.then do |payload|
        if self.control != self.hexdigest(payload)
          self.new(source: self.source, payload: payload).tap do |instance|
            self.instance = instance
            self.control = instance.control
          end
        end

        @instance
      end
    end

    protected

    # @return [self]
    attr_writer :instance

    # @return [String, nil]
    attr_accessor :control

    # @return [Class<ENV>]
    def source
      ENV
    end

    # @param [Object] payload
    #
    # @return [String]
    def hexdigest(payload)
      JSON.generate(payload).then { |str| Digest::SHA2.hexdigest(str) }
    end
  end
end
