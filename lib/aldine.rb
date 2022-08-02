# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

$LOAD_PATH.unshift(__dir__)

require 'English'

# Namespace module
module Aldine
  autoload(:Pathname, 'pathname')

  Pathname.new(__dir__).join('aldine').then do |libdir|
    {
      Bundleable: :bundleable,
      Cli: :cli,
      Remote: :remote,
      Shell: :shell,
      Local: :local,
    }.each { |k, v| autoload(k, libdir.join(v.to_s)) }

    include Bundleable

    # @todo use autoload mechanism to set VERSION constant
    lambda do
      require('kamaze/version')

      self.const_set(:VERSION, ::Kamaze::Version.new(libdir.join('version.yml')).freeze)
    end.then do |f|
      f.call unless self.constants(false).include?(:VERSION)
    end
  end
end
