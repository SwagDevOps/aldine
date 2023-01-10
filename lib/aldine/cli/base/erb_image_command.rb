# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Base for templated image command.
#
# @abstract
class Aldine::Cli::Base::ErbImageCommand < Aldine::Cli::Base::ErbCommand
  include ::Aldine::Cli::Commands::Concerns::ImageMatch
  include ::Aldine::Cli::Commands::Concerns::SvgConvert
  autoload(:Pathname, 'pathname')

  class << self
    protected

    def overridables
      {
        caption: :param_caption,
        label: :param_label,
      }.then { |overridables| (super || {}).merge(overridables) }
    end
  end

  protected

  # Translates source (filepath without extension) to the best matching file.
  #
  # @return [Pathname]
  def input_file
    image_match!(source)
  end

  def output_basepath
    source.expand_path.to_path
  end

  # Get caption used for the image.
  def caption
    self.param_caption.to_s.then do |s|
      s.strip.empty? ? nil : s
    end
  end

  # Get label used for the image.
  def label
    self.param_label.to_s.then do |s|
      s.strip.empty? ? nil : s
    end
  end

  # Get a converter to convert image.
  #
  # @return [Proc]
  def converter
    # @type [Pathname] input_file
    lambda do |input_file|
      input_file.extname == '.svg' ? svg_convert(input_file) : input_file
    end
  end

  # @return [Pathname]
  def conversion
    self.input_file.then do |input_file|
      self.converter.call(input_file).tap do |image_path|
        unless image_path.is_a?(Pathname) and image_path.file? and image_path.readable?
          throw RuntimeError, "Failed to convert image: #{input_file}"
        end
      end
    end
  end

  # @!attribute [rw] param_caption
  #   @return [String, nil]

  # @!attribute [rw] param_label
  #   @return [String, nil]

  {
    caption: 'caption for the image',
    label: 'label for the image',
  }.each do |option_name, description|
    {
      attribute_name: "param_#{option_name}",
    }.tap do |options|
      option("--#{option_name}", option_name.to_s.upcase, description, options)
    end
  end
end
