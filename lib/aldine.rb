# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

$LOAD_PATH.unshift(__dir__)

require 'English'

# Namespace module
module Aldine
  autoload(:Pathname, 'pathname')

  # @type [Pathname]
  RESOURCES_DIR = Pathname.new(__FILE__.gsub(/\.rb$/, '')).join('resources').realpath.freeze

  Pathname.new(__dir__).join('aldine').then do |libdir|
    {
      Bundleable: :bundleable,
      Cli: :cli,
      Concerns: :concerns,
      DotenvLoader: :dotenv_loader,
      Local: :local,
      Remote: :remote,
      Settings: :settings,
      Shell: :shell,
      Utils: :utils,
    }.each { |k, v| autoload(k, libdir.join(v.to_s)) }

    # @todo due to a "bug" in bundleable version can not be autoloaded - SHOULD fix bunleable
    require(libdir.join('version').to_s).then { include(Bundleable) }
  end

  class << self
    # Load environment variables from ``.env`` file into ``ENV``.
    #
    # @return [Hash{String => String}]
    def dotenv(&block)
      DotenvLoader.new.then do |dotenv|
        dotenv.call(&block)
              .tap { ::Aldine::Settings.boot(reload: true) }
      end
    end
  end
end
