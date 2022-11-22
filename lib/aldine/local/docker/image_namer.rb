# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Utility used to build an image name using configurable template-string.
class Aldine::Local::Docker::ImageNamer
  autoload(:Pathname, 'pathname')
  include(::Aldine::Concerns::HasInflector)
  include(::Aldine::Concerns::SettingsAware)

  # @param [Struct] user
  # @param [Pathname] path
  def initialize(user:, path: nil)
    self.user = user
    self.path = path || Pathname.pwd
  end

  # @return [String]
  def call
    renderable.call(variables)
  end

  protected

  # @type [Struct]
  attr_accessor :user

  # @type [Pathname]
  attr_accessor :path

  def variables
    {
      user_name: self.user.name,
      user_uid: self.user.uid,
      user_gid: self.user.gid,
      path_slug: self.path.basename.to_s.then { |dirname| self.inflector.underscore(dirname) },
      output_name: settings.get('output_name'),
    }
  end

  # @return [String]
  def template
    settings.get('container.image_name')
  end

  # @return [Aldine::Utils::TemplateString]
  def renderable
    ::Aldine::Utils::TemplateString.new(template)
  end
end
