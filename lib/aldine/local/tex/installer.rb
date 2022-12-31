# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../tex'

# Installer for packages provided from (local) resources.
class Aldine::Local::Tex::Installer
  include(::Aldine::Concerns::SettingsAware)
  include(::Aldine::Concerns::HasLocalShell)
  include(::Aldine::Concerns::HasLocalFileSystem)

  def initialize
    self.tap do
      @active = settings.get('tex.packages.install')
      @packages_dir = Aldine::Local::RESOURCES_DIR.join('packages')
      @install_dir = settings.get('directories.lib').then { |path| Pathname.pwd.join(path) }
    end.freeze
  end

  # Install provided packages.
  #
  # @return [Array<Symbol>]
  def call
    self.packages.map do |name, path|
      self.install_package(name.to_s, path).then { name }
    end
  end

  # Get list of installable packages.
  #
  # @return [Array<Symbol>]
  def to_a
    self.packages.keys
  end

  # Denote installer should run.
  #
  # @return [Boolean]
  def active?
    !!@active
  end

  protected

  # Get path to packages from resources.
  #
  # @return [Pathname]
  attr_reader :packages_dir

  # Get path where to install packages.
  #
  # @return [Pathname]
  attr_reader :install_dir

  # Get a dictionnary of packages (as absolute paths indexed by names).
  #
  # @return [Hash{Symbol => Pathname}]
  def packages
    self.active? ? available_packages : {}
  end

  # @param [String] name
  # @param [Pathname] original_path
  #
  # @return [Boolean]
  def install_package(name, original_path)
    install_dir.join(name.to_s).then do |copy_path|
      self.fs(silent: true).then do |fs|
        fs.rm_rf(copy_path)
        fs.mkdir_p(copy_path.dirname, verbose: false) unless copy_path.dirname.directory?
        fs.copy_entry(original_path, copy_path)
      end
    end.then { true }
  end

  # @return [Hash{Symbol => Pathname}]
  def available_packages
    packages_dir.entries.map do |path|
      [
        path.to_path.to_sym,
        packages_dir.join(path.to_path).realpath
      ].then do |v|
        (path.to_path[0] != '.' and v[1].directory?) ? v : nil
      end
    end.compact.to_h
  end
end
