# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# @!parse Aldine::VERSION = ::Kamaze::Version.new("#{__dir__}/version.yml").freeze
require_relative('../aldine').then { ::Aldine }.then do |subject|
  lambda do
    require('kamaze/version').then do
      ::Kamaze::Version.new("#{__dir__}/version.yml").freeze
    end.then do |version|
      subject.__send__(:const_set, :VERSION, version)
    end
  end.then do |f|
    f.call unless subject.constants(false).include?(:VERSION)
  end
end
