# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Config with dot-notation access acting as a singleton.
class Aldine::Cli::App::Config
  class << self
    # @return [Aldine::Cli::App::Config]
    def instance
      self.instance = @instance || self.new
    end

    protected

    # @type [Aldine::Cli::App::Config]
    attr_writer :instance
  end

  "#{__dir__}/config".then do |libdir|
    {
      Index: :index,
    }.each { |k, v| autoload(k, "#{libdir}/#{v}") }
  end

  autoload(:Pathname, 'pathname')
  autoload(:YAML, 'yaml')

  include(::Aldine::Concerns::SettingsAware)

  # Access the payload with a dot-notation.
  #
  # @param [String, Symbol] path
  #
  # @return [Object]
  def get(path, default = nil, &block)
    self.index.get(path, default, &block)
  end

  protected

  # @return [Pathname]
  attr_reader :path

  # @return [Index]
  attr_reader :index

  # @param [String] path
  def initialize(path = nil)
    self.tap do
      self.path = path || settings.get('cli.config_path')
      @index = make_index(self.path)
    end.freeze
  end

  # @param [String] path
  def path=(path)
    path
      .then { |v| Pathname.new(v) }
      .then { |v| v.absolute? ? v : Pathname.pwd.join(v) }
      .then { |v| @path = v.freeze }
  end

  # @param [Pathname] path
  #
  # @return [Index]
  def make_index(path)
    path.glob('**/*.yml').sort.map do |file|
      [
        file.to_s.gsub(%r{^#{self.path}/*}, '').gsub(/\.yml/, ''),
        file.read.then { |contents| YAML.safe_load(contents) }
      ]
    end.then { |index| Index.new(index) }.deep_freeze
  end
end
