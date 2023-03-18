# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../concerns'

# Provides access to file system.
module Aldine::Concerns::HasLocalFileSystem
  protected

  # @return [Module<FileUtils>, Module<FileUtils::Verbose>]
  def fs(silent: false)
    require('fileutils').then do
      ::FileUtils::Verbose.instance_variable_set(:@fileutils_output, $stderr)

      silent ? ::FileUtils : ::FileUtils::Verbose
    end
  end
end
