# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Produce all full/big image markup.
class Aldine::Cli::Commands::ImageFullCommand < Aldine::Cli::Base::ErbCommand
  include ::Aldine::Cli::Commands::Concerns::ImageMatch
  include ::Aldine::Cli::Commands::Concerns::SvgConvert

  def output_basepath
    source.expand_path.to_path
  end

  # Translates source (filepath without extension) to the best matching file.
  #
  # @return [Pathname]
  def input_file
    image_match!(source)
  end

  protected

  def variables_builder
    lambda do
      {
        caption: nil, # @todo add an option to set caption
        label: nil, # @todo add an option to set label
        input_file: self.input_file,
        image_file: input_file.extname == '.svg' ? svg_convert(input_file) : input_file,
      }
    end
  end
end
