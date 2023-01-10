# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../shell'

# Describe a shell error (comand execution without success return code).
class Aldine::Shell::CommandError < ::RuntimeError
  autoload(:Shellwords, 'shellwords')

  # @param [Array<String>] command
  # @param [Process::Status] status
  def initialize(command, status: nil)
    super().tap do
      @command = command.to_a.clone.map(&:freeze).freeze
      @message = Shellwords.join(command).freeze
      @status = status.freeze
    end
  end

  # @return [String]
  attr_reader :message

  alias to_s message

  # @return [Process::Status]
  attr_reader :status

  # @return [Array<String>]
  attr_reader :command
end
