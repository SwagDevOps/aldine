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
#
# Sample of use
#
# ```latex
# \aldineDropcap{Example of use for lettrine/dropcap}[
#     font: GotIn,
#     config: "lines=3, lraise=0.15",
# ].
# ```
#
# Can be configured through settings (`` cli.commnads.dropcap.defaults`` on ``font`` and ``lettrine_config``).
#
# @see https://texdoc.org/serve/lettrine.pdf/0
# @see https://tug.org/FontCatalogue/otherfonts.html
class Aldine::Cli::Commands::DropcapCommand < Aldine::Cli::Base::ErbCommand
  parameter('SOURCE', 'source word (sentence or chars)', { attribute_name: :param_source })

  class << self
    include(::Aldine::Concerns::SettingsAware)

    protected

    # @api private
    #
    # @return [Hash{Symbol => Object}]
    def defaults
      'cli.commnads.dropcap.defaults'.then do |base_path|
        {
          font: 'ArtNouv',
          lettrine_config: 'lines=3, loversize=0.1',
        }.map do |k, v|
          [k, self.settings.get("#{base_path}.#{k}", v)]
        rescue KeyError
          [k, v]
        end
      end.to_h.freeze
    end
  end

  option('--font', 'FONT',
         'font used to render dropcap',
         {
           default: defaults.fetch(:font),
           attribute_name: :param_font
         }, &:to_s)
  option('--[no-]load-fd', :flag, 'load font-description', { default: true })

  option('--config', 'CONFIG',
         'config/options used by lettrine package',
         {
           default: defaults.fetch(:lettrine_config),
           attribute_name: :param_lettrine_config
         }, &:to_s)

  class << self
    protected

    def overridables
      {
        font: :param_font,
        load_fd: nil,
        lettrine_config: :param_lettrine_config,
      }.then { |override| super.merge(override) }
    end
  end

  protected

  def variables
    self.parts.then do |parts|
      {
        font: font,
        fd: self.load_fd? ? "#{font}.fd" : nil,
        config: lettrine_config,
        first_char: parts.fetch(0),
        remaining_chars: parts.fetch(1),
      }
    end
  end

  # @return [Hash{Symbol => Object}]
  def defaults
    self.class.__send__(:defaults)
  end

  # @!attribute [r] param_font
  #   @see https://tug.org/FontCatalogue/otherfonts.html
  #   @return [String, nil]

  # @!method load_fd?
  #   Denotes font-description is loaded.
  #   @return [Boolean]

  # @!attribute [r] param_lettrine_config
  #   @return [String, nil]

  # Get font used in template (according to given option or default).
  def font
    param_font || defaults.fetch(:font)
  end

  # Get config for lettrine package.
  def lettrine_config
    param_lettrine_config || defaults.fetch(:lettrine_config)
  end

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
end
