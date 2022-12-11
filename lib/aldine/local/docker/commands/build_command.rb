# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../commands'

# Describe ``build`` command for container.
class Aldine::Local::Docker::Commands::BuildCommand < Aldine::Local::Docker::Commands::BaseCommand
  autoload(:Pathname, 'pathname')

  # @api private
  BUILD_PATH = Aldine::Local::RESOURCES_DIR.join('docker').freeze

  # @param [String] image
  # @param [String, nil] path
  def initialize(image:, path: nil)
    super.tap do
      self.image = image
      self.path = shell.pwd.join(path || default_path)
    end.freeze
  end

  def to_a
    super
      .concat(['build', '-t', image])
      .concat(settings.get('directories').map { |k, v| ['--build-arg', "#{k}_dir=#{v}"] }.flatten)
      .concat(settings.get('container.build.args').map { |k, v| ['--build-arg', "#{k}=#{v}"] }.flatten)
      .concat([build_path.relative_path_from(shell.pwd).to_path])
  end

  protected

  # @type [String]
  attr_accessor :image

  # Path from where image is built.
  #
  # @type [Pathname]
  # @return [Pathname]
  attr_accessor :path

  def default_path
    settings.get('container.build.path')
  end

  def build_path
    self.path.directory? ? self.path : BUILD_PATH
  end
end
