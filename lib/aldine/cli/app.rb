# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../cli'

# Cli app based on top of clamp.
#
# @see https://github.com/mdub/clamp
class Aldine::Cli::App < ::Clamp::Command
  autoload(:Pathname, 'pathname')

  {
    Loader: 'loader',
  }.each { |k, v| autoload(k, "#{__dir__}/app/#{v}") }

  # Execute is triggered when no subcommands are found.
  #
  # Print an error message on STDERR and exit with an error status code.
  def execute
    warn('No commands implemented at the moment.')

    Errno::ENOTSUP::Errno.tap { |status| exit(status) }
  end

  # noinspection YARDTagsInspection
  class << self
    # Create an instance of this command class, and run it.
    #
    # @param [String] invocation_path the path used to invoke the command
    # @param [Array<String>] arguments command-line arguments
    # @param [Hash] context additional data the command may need
    def call(...)
      self.boot
          .then { self.run(...) }
    end

    # @return [self]
    def boot
      self.tap do
        ::Aldine
          .dotenv
          .then { load_commands }
      end
    end

    protected

    # @return [String]
    def invocation_path
      File.basename($PROGRAM_NAME)
    end

    # Get paths from where subcommands are loaded.
    #
    # @return [Array<Pathname>]
    def paths
      [
        __dir__&.then { |dir| Pathname.new(dir).join('commands') }
      ].compact
    end

    def loader
      Loader.new(self.paths)
    end

    def load_commands
      # Load commands -------------------------------------------------------------
      loader.call { |name, info| subcommand(name, info.description, info.loader.call) }
    end
  end
end
