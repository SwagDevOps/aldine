# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
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

  Pathname.new(__dir__).join('aldine').then do |libdir|
    {
      Bundleable: :bundleable,
      Cli: :cli,
      Local: :local,
      Remote: :remote,
      Shell: :shell,
      Utils: :utils,
    }.each { |k, v| autoload(k, libdir.join(v.to_s)) }

    include Bundleable

    # @todo use autoload mechanism to set VERSION constant
    lambda do
      require('kamaze/version')

      self.const_set(:VERSION, ::Kamaze::Version.new(libdir.join('version.yml')).freeze)
    end.then do |f|
      f.call unless self.constants(false).include?(:VERSION)
    end
  end

  class << self
    # @api private
    ENV_FILES = %w[.env.local .env].freeze

    # Load environment variables from ``.env`` file into ``ENV``.
    #
    # @param [Array<String>|nil] files
    #
    # @return [Hash{String => String}]
    def dotenv(files = nil, &block)
      require 'dotenv'
      require 'dotenv_validator'

      # noinspection RubyResolve
      ::Dotenv.load(*(files || ENV_FILES))
              .tap { ::DotenvValidator.check! }
              .tap { block&.call }
    end
  end
end
