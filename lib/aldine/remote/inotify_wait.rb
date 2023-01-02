# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

# Wrapper built on top of ``inotifywait``
class Aldine::Remote::InotifyWait < ::Aldine::Shell::Readline
  autoload(:YAML, 'yaml')

  def initialize(*paths, env: {})
    @silent = true
    super(self.class.command.concat(paths), env: env)
  end

  # rubocop:disable Metrics/MethodLength

  def call(&block)
    super do |stream, **kwargs|
      if kwargs[:source].eql?(:stdout)
        stream.each_line do |line|
          YAML.safe_load(line).tap do |h|
            block.call(h.keys.fetch(0), h.values.fetch(0))
          end
        end
      else
        stream.each_line { |line| warn(line) }
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  class << self
    def command
      [
        'inotifywait',
        '-e', 'CLOSE_WRITE', '-e', 'DELETE', '-e', 'MOVED_TO', '-e', 'CREATE',
        '--format', '{"%w%f": [%e]}', '-rm'
      ]
    end
  end
end
