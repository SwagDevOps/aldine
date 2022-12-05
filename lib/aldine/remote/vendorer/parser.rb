# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../vendorer'

# Parser for YAML configuration file.
class Aldine::Remote::Vendorer::Parser
  autoload(:YAML, 'yaml')

  # @param [Pathname] file
  #
  # @return [Array<Hash{Symbol => Object}>]
  def call(file)
    self.read(file)
        .then { |payload| self.prepare(payload) }
        .then { |payload| self.transform(payload) }
  end

  protected

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # Transform values seen in YAML manifest.
  #
  # @param [Array<Hash{Symbol => Object}>] payload
  #
  # @return [Array<Hash{Symbol => Object}>]
  def transform(payload)
    payload.map do |h|
      h.tap { h[:options] = (h[:options] || {}).transform_keys(&:to_sym) if h[:options] }
    end.map do |h|
      h.tap do
        if (h[:options] || {}).empty?
          [:ref, :tag, :branch].each do |k|
            h[:options] = (h[:options] || {}).merge({ k => h[k] }) if h[k]
            h.delete(k)
          end
        end
      end
    end.map { |h| h.sort_by { |k, _| k }.to_h }
  end

  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  # @param [Array<Hash{Symbol => Object}>, nil] payload
  #
  # @return [Array<Hash{Symbol => Object}>]
  def prepare(payload)
    # options hash is present depending on type folder - type folder is implicit and preferred
    f = lambda do |h|
      (h[:type] || 'folder').then do |type|
        {
          type: type,
          options: type == 'folder' ? h.fetch(:options, {}) : nil,
        }.compact.then { |v| h.merge(v) }
      end
    end

    (payload || {})
      .map { |k, v| v.merge({ path: k }) }
      .map { |h| h.transform_keys(&:to_sym) }
      .keep_if { |h| ![h[:path], h[:url]].map(&:to_s).include?('') }
      .map { |h| f.call(h) }
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  # Read yaml file.
  #
  # @todo Handle exceptions gracefully
  # @return [Array<Hash{Symbol => Object}>, nil]
  def read(file)
    YAML.safe_load(file.read)
  end
end
