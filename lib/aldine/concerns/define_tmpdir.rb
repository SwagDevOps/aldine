# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../concerns'

# Provides ``define_tmpdir`` method.
module Aldine::Concerns::DefineTmpdir
  autoload(:Pathname, 'pathname')

  # Define ``tmpdir`` on given attribute (using accessor)
  #
  # @param [Symbol] attribute
  # @param [Pathname, String, nil] tmpdir
  #
  # @return [self]
  def define_tmpdir(attribute, tmpdir: nil)
    lambda do
      require 'tmpdir'

      Pathname.new(Dir.tmpdir).expand_path
    end.then do |functor|
      self.__send__("#{attribute}=", Pathname.new(tmpdir || functor.call))
    end
  end
end
