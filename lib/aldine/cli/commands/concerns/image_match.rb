# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../../app'

# Provide methods to match image files with a filepath without extension (``source``).
module Aldine::Cli::Commands::Concerns::ImageMatch
  protected

  # Get best match for given filepath without extension.
  #
  # @note Fails on empty result.
  #
  # @param [Pathname] source
  #
  # @return [Pathname]
  def image_match!(source)
    image_match(source).tap do |match|
      if match.nil?
        raise "Can not match image file with as #{source.to_path.inspect}"
      end
    end
  end

  # Get best match for given filepath without extension.
  #
  # @param [Pathname] source
  #
  # @return [Pathname, nil]
  def image_match(source)
    images_matcher.call(source).values.first
  end

  # Get instance of images matcher.
  #
  # @return [Aldine::Cli::Commands::Shared::FilesMatcher]
  def images_matcher
    ::Aldine::Cli::Commands::Shared::FilesMatcher.new(images_extensions)
  end

  # @return [Array<Symbol>]
  def images_extensions
    [:pdf, :svg, :png, :jpg, :jpeg].freeze
  end
end
