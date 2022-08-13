# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Warpper built around rake execution.
class Aldine::Local::Docker::RakeRunner
  FILE = ::Aldine::Remote::RESOURCES_DIR.join('rake/Rakefile').realpath

  # @param [Proc] runner
  def initialize(runner)
    self.runner = runner
  end

  # @param [String] task
  def call(task, **options)
    command_for(task).then do |command|
      self.runner.call(command, **options)
    end
  end

  protected

  # @return [Proc]
  attr_accessor :runner

  # @return [Array<String>]
  def command_for(task)
    %w[bundle exec rake].concat([task]).map(&:to_s)
  end
end
