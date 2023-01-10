# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Basic command.
#
# @abstract
class Aldine::Cli::Base::BasicCommand < Aldine::Cli::Command
  autoload(:Pathname, 'pathname')
  "#{__dir__}/basic_command".tap do |path|
    {
      Concerns: :concerns,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end

  class << self
    include(::Aldine::Cli::Base::BasicCommand::Concerns::Help)
    include(::Aldine::Cli::Base::BasicCommand::Concerns::Parameters)

    # Generate the help message.
    #
    # @param [String] invocation_path
    # @param [Clamp::Help::Builder, nil] builder
    #
    # @return [String]
    def help(invocation_path, builder = nil)
      with_help(invocation_path, builder) { |help| help_renderer.call(help) }
    end

    protected

    # @param [Class<Aldine::Cli::Base::BaseCommand>] subclass
    def inherited(subclass, &block)
      super(subclass).then { block&.call(subclass) }
    end
  end

  protected

  # Returns the operating system's temporary file path.
  #
  # @return [Pathname]
  def tmpdir
    lambda do
      require('tmpdir').then { ::Dir.tmpdir }
    end.yield_self do |tmp|
      Pathname.new(ENV.fetch('TMPDIR', tmp.call)).expand_path
    end
  end
end
