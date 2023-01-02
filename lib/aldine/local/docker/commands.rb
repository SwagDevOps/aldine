# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Namespace module for commands.
module Aldine::Local::Docker::Commands
  __FILE__.gsub(/\.rb$/, '').tap do |path|
    {
      BaseCommand: :base_command,
      BuildCommand: :build_command,
      RunCommand: :run_command,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end
end
