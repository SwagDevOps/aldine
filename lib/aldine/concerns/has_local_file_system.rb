# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../concerns'

# Provides access to ``shell``.
module Aldine::Concerns::HasLocalFileSystem
  protected

  # @return [Module<FileUtils>, Module<FileUtils::Verbose>]
  def fs(silent: false)
    # @type [::Aldine::Local::Shell] shell
    (self.is_a?(::Aldine::Concerns::HasLocalShell) ? shell : ::Aldine::Local::Shell)
      .then { |shell| shell.fs(silent: silent) }
  end
end
