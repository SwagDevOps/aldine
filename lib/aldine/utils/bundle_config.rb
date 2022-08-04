# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../utils'

# Bundle config reader.
class Aldine::Utils::BundleConfig
  autoload(:Pathname, 'pathname')
  autoload(:YAML, 'yaml')

  def initialize(basedir)
    super().tap do
      self.basedir = Pathname.new(basedir)
    end.freeze
  end

  def read
    filepath.read.then do |content|
      YAML.safe_load(content)
    end
  end

  protected

  attr_accessor :basedir

  def filepath
    self.basedir.join('.bundle/config')
  end
end
