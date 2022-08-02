# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../../app'

# Files matcher
#
# Provide methods to match files with a filepath without extension (``source``).
class Aldine::Cli::Commands::Shared::FilesMatcher
  # @param [Array<Symbols>] extensions
  def initialize(extensions)
    super().tap do
      self.extensions = extensions.map(&:to_sym).freeze
    end.freeze
  end

  # Get matches based on source.
  #
  # Matches are indexed by file extension, and sorted by extensions precedence.
  #
  # @param [Pathname] source
  #
  # @return [Hash{Symbol => Pathname}]
  def call(source)
    source.expand_path.dirname.glob("#{source.basename}.*").then do |matches|
      matches
        .map { |match| [match.extname.to_s.downcase.gsub(/^\./, '').to_sym, match] }
        .keep_if { |ext, _| searched_extensions.include?(ext) }
        .sort_by { |ext, _| searched_extensions.find_index(ext) || matches.length }
        .to_h
    end
  end

  protected

  # @return [Array<Symbols>]
  attr_accessor :extensions

  alias searched_extensions extensions
end
