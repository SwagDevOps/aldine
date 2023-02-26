# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Process given word (or sentence) to apply dropcap (through lettrine package).
class Aldine::Cli::Commands::DropcapCommand < Aldine::Cli::Base::ErbCommand
  # Default lettrine font.
  #
  # @todo Use a more global mechanism to set this.
  #
  # @api private
  DEFAULT_FONT = 'ArtNouv'

  # Default lettrine config.
  #
  # @todo Use a more global mechanism to set this.
  #
  # @api private
  LETTRINE_CONFIG = 'lines=3, loversize=0.1'

  parameter('SOURCE', 'source word (sentence or chars)', { attribute_name: :param_source })

  option('--font', 'FONT',
         'font used to render dropcap',
         {
           default: DEFAULT_FONT,
           attribute_name: :param_font
         }, &:to_s)

  option('--lettrine-config', 'LETTRINE_CONFIG',
         'options used by lettrine package',
         {
           default: LETTRINE_CONFIG,
           attribute_name: :param_lettrine_config
         }, &:to_s)

  class << self
    protected

    def overridables
      {
        font: :param_font,
        lettrine_config: :param_lettrine_config,
      }.then { |override| super.merge(override) }
    end
  end

  protected

  # @!attribute [r] param_font
  #   @see https://tug.org/FontCatalogue/otherfonts.html
  #   @return [String, nil]

  # @!attribute [r] param_lettrine_config
  #   @return [String, nil]

  # Get parts from given word or sentence.
  #
  # Returns a tuple of 2 items, as first char and remaining chars (without the first).
  #
  # @return [Array<String>]
  def parts
    source.to_s.then do |base|
      base.chars.fetch(0).then do |first_char|
        return [
          first_char,
          base.gsub(/^#{first_char}/, ''), # remaining chars
        ].map(&:freeze).freeze
      end
    end
  end

  def output_basepath
    parts.fetch(0)
  end

  def variables_builder
    lambda do
      self.parts.then do |parts|
        {
          font: param_font || DEFAULT_FONT,
          lettrine_config: param_lettrine_config || LETTRINE_CONFIG,
          first_char: parts.fetch(0),
          remaining_chars: parts.fetch(1),
        }
      end
    end
  end
end
