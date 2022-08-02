# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

autoload(:Pathname, 'pathname')

# Synchronize directories based on rsync
class Aldine::Remote::Synchro < Aldine::Shell::Command
  def initialize(origin, target, env: {})
    [
      "#{Pathname.new(origin).expand_path}/",
      Pathname.new(target).expand_path.to_s
    ].tap do |paths|
      self.class.command.concat(paths).tap { |command| super(command, env: env) }
    end
  end

  class << self
    def command
      %w[rsync -raHq --delete]
    end
  end
end
