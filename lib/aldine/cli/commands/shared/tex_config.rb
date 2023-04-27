# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../../app'

# Parse a tex-config with key/values comma separated.
#
# Example:
#
# ```
# font=ArtNouv, lines=3, loversize=0.1
# ```
class Aldine::Cli::Commands::Shared::TexConfig
  # @param [String] config
  def initialize(config)
    @config = (config.is_a?(::String) and !config.strip.empty?) ? config.strip : nil
  end

  # @return [Hash{Symbol => String]}]
  def to_h
    @parsed ||= self.parse
  end

  def [](key)
    self.to_h[key]
  end

  def to_s
    self.config.dup
  end

  # @return [String]
  def dump(except: [])
    self.to_h.then do |h|
      except.empty? ? h : h.except(*except)
    end.map { |k, v| "#{k}=#{v}" }.join(', ')
  end

  protected

  # @return [String, nil]
  attr_reader :config

  # @return [Hash{Symbol => String]}]
  attr_reader :parsed

  # @return [Hash{Symbol => String]}]
  def parse
    return {} unless config

    self.config.split(/,\s+/).map do |raw|
      raw.match(/^([A-Z a-z]+([A-Z a-z]|_)*[A-Z a-z]*)=/).to_a[1].then do |key|
        next unless key

        [key, make_value(key, raw)]
      end
    end.to_h.transform_keys(&:to_sym)
  end

  def make_value(key, raw)
    raw.rstrip.gsub(/^#{key}=/, '').then do |s|
      (s.match(/^'.+'$/) or s.match(/^".+"$/)) ? s[1..-2] : s
    end
  end
end
