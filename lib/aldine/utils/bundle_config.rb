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

  # @param [String, Pathname] basedir
  def initialize(basedir)
    super().tap do
      self.basedir = Pathname.new(basedir)
    end.freeze
  end

  # @return [Hash{String => String}]
  def read
    filepath.read.then do |content|
      YAML.safe_load(content)
    end
  end

  # @return [String]
  def to_path
    filepath.to_path
  end

  # @return [Pathname]
  def realpath
    filepath.realpath
  end

  # @return [String]
  def bundle_path
    read.fetch('BUNDLE_PATH')
  end

  # @return [Pathname]
  def bundle_basedir
    bundle_path
      .then { |path| Pathname.new(path) }
      .then { |path| ensure_relative_path(path, from: basedir) }
      .then { |path| path.to_path.gsub(%r{^(\./+)+}, '').split('/').compact.first }
      .then { |basedir| self.basedir.join(basedir) }
  end

  protected

  # @return [Pathname]
  attr_accessor :basedir

  # Get path to config file.
  #
  # @return [Pathname]
  def filepath
    self.basedir.join('.bundle/config')
  end

  # @param [Pathname] path
  # @param [Pathname] from
  #
  # @return [Pathname]
  def ensure_relative_path(path, from:)
    raise "given path #{path.to_path.inspect} is not a relative path" unless path.relative?

    from.join(path).relative_path_from(from).then do |relative_path|
      raise 'relative path can not traverse the file system' if relative_path.to_path.match(%r{\.{2}/})

      relative_path
    end
  end
end
