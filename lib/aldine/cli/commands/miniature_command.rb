# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Produce miniature markup.
#
# @see https://www.overleaf.com/learn/latex/Wrapping_text_around_figures
# @todo Use different template depending on float option.
class Aldine::Cli::Commands::MiniatureCommand < Aldine::Cli::Base::ErbImageCommand
  class << self
    protected

    # @return [Hash{Symbol => Object}]
    def defaults
      false.then do |floating|
        {
          floating: floating,
          width: 2.0,
          margin: 0.1,
          position: self.positions.values.fetch(0).to_s.__send__(floating ? :upcase : :downcase),
        }
      end
    end

    # Positions.
    #
    # The uppercase version allows the figure to float. The lowercase version means exactly here.
    #
    # @return [Hash{Symbol => String}]
    def positions
      {
        right: 'r',
        left: 'l',
        inside: 'i',
        outside: 'o',
      }
    end

    def overridables
      {
        width: :param_width,
        margin: :param_margin,
        position: :param_position,
      }.then { |overridables| (super || {}).merge(overridables) }
    end
  end

  # @!attribute [rw] param_width
  #   @return [Float, nil]

  # @!attribute [rw] param_margin
  #   @return [Float, nil]

  # @!attribute [rw] param_position
  #   @return [String, nil]

  # @!method floating?
  #   Denote image is supposed to float.
  #
  #   @return [Boolean]

  # set command options
  begin
    {
      width: 'image width',
      margin: 'image margin',
    }.each do |k, desc|
      { default: self.defaults[k], attribute_name: "param_#{k}" }.then do |opts|
        option("--#{k}", k.to_s.upcase, desc, opts) { |s| Float(s) }
      end
    end

    option('--[no-]floating', :flag, 'miniature is floating', default: self.defaults.fetch(:floating))

    {
      default: self.defaults.fetch(:position),
      attribute_name: 'param_position',
    }.tap do |opts|
      option('--position', 'POSITION', 'miniature position', opts) do |s|
        self.class.__send__(:positions).fetch(s.to_sym, s).to_s
      end
    end
  end

  protected

  # Get position (set from options, or default).
  #
  # @return [String]
  def position
    (self.param_position || self.defaults.fetch(:position)).to_sym.then do |v|
      return (self.class.__send__(:positions)[v] || v).to_s
    end.then do |v|
      self.floating? ? v.upcase : v
    end
  end

  # Get image margin (as set from options, or default).
  #
  # @return [Float]
  def margin
    # noinspection RubyMismatchedReturnType
    self.param_margin || defaults[:margin]
  end

  # Get image width (as set from options, or default).
  #
  # @return [Float]
  def width
    # noinspection RubyMismatchedReturnType
    self.param_width || defaults[:width]
  end

  # @return [Hash{Symbol => Object}]
  def defaults
    self.class.__send__(:defaults)
  end

  # Get dimensions, used in template.
  #
  # @return [Array<Float>]
  def dimensions
    [width + margin, width].freeze
  end

  def variables_builder
    lambda do
      {
        caption: self.caption,
        label: self.label,
        input_file: self.input_file,
        image_file: self.conversion,
        dimensions: self.dimensions,
        position: self.position,
      }
    end
  end
end
