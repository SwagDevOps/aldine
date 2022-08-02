# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Base command.
#
# @abstract
class Aldine::Cli::Base::BaseCommand < Aldine::Cli::Command
  autoload(:Pathname, 'pathname')

  class << self
    protected

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
      require 'tmpdir'

      Dir.tmpdir
    end.yield_self do |tmp|
      Pathname.new(ENV.fetch('TMPDIR', tmp.call)).expand_path
    end
  end
end
