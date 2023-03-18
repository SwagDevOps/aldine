# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../../app'

# Provide method to convert SVG files to PDF.
#
# @see Aldine::Cli::Commands::Shared::SvgConv
module Aldine::Cli::Commands::Concerns::SvgConvert
  protected

  # Convert given file (to PDF).
  #
  # @param [Pathname] filepath
  #
  # @return [Pathname] as output file
  def svg_convert(filepath)
    svg_converter.call(filepath)
  end

  # Get an instance of ``SvgConv`` ready to process files.
  #
  # @api private
  #
  # @return [Aldine::Cli::Commands::Shared::SvgConv]
  def svg_converter
    ::Aldine::Cli::Commands::Shared::SvgConv.new(**svg_converter_options)
  end

  # @return [Hash{Symbol => Object}]
  def svg_converter_options
    {
      cache: self.respond_to?(:cache?, true) ? self.__send__(:cache?) : true,
      debug: self.respond_to?(:debug?, true) ? self.__send__(:debug?) : false,
      tmpdir: self.respond_to?(:tmpdir, true) ? self.__send__(:tmpdir) : nil,
    }
  end
end
