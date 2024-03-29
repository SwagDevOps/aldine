# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../commands'

# Base command.
#
# @abstract
class Aldine::Local::Docker::Commands::BaseCommand
  include(::Aldine::Concerns::SettingsAware)
  include(::Aldine::Concerns::HasLocalShell)

  def initialize(*)
    super()
  end

  # @abstract
  #
  # @return [Array<String>]
  def to_a
    %w[/usr/bin/env docker]
  end

  # @return [Process::Status]
  def call(exception: true, silent: false)
    self.shell.sh(*self.to_a, exception: exception, silent: silent)
  end
end
