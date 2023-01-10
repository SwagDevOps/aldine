# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../aldine'

# Module related to rake local tasks.
module Aldine::Local
  autoload(:Pathname, 'pathname')

  # @type [Pathname]
  RESOURCES_DIR = Pathname.new(__FILE__.gsub(/\.rb$/, '')).join('resources').realpath.freeze

  "#{__dir__}/local".tap do |path|
    {
      Docker: 'docker',
      Shell: 'shell',
      Tex: 'tex',
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end
end
