# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Wrap docker run commands.
#
# Create directories and create files used as volumes.
#
# @see Aldine::Local::Docker::Commands::RunCommand#bundle_dirs
class Aldine::Local::Docker::AroundExecute
  include(::Aldine::Concerns::SettingsAware)
  include(::Aldine::Concerns::HasLocalShell)
  include(::Aldine::Concerns::HasLocalFileSystem)

  # @api private
  TMP_BUNDLE_PATH = '.sys/bundle'

  # @param [Array<String, Pathname>] directories
  # @param [String] tmpdir
  def initialize(directories, tmpdir:)
    super().tap do
      self.tmpdir = Pathname.new(tmpdir).freeze
      directories.dup.concat(bundle_tmpdirs.values).map { |fp| Pathname.new(fp) }.tap do |v|
        self.directories = v.freeze
      end
    end.freeze
  end

  def call(&execute_stt)
    prepare.then { execute_stt.call }
  end

  # Get directories used for bundle share and persistance.
  #
  # @return [Hash{Symbol => Pathname}]
  def bundle_tmpdirs
    %w[pack conf home]
      .map { |dir| [dir.to_sym, bundle_tmpdir.join(dir)] }
      .concat([[:base, bundle_tmpdir]]) # base (root) of bundle_tmpdir - is first
      .sort_by { |a| a.fetch(0) == :base ? '' : a.fetch(0).to_s }
      .to_h
  end

  protected

  # @return [Array<Pathname>]
  attr_accessor :directories

  # @return [Pathname]
  attr_accessor :tmpdir

  # rubocop:disable Naming/MethodParameterName

  # Create required files and directories.
  #
  # @param [Module<FileUtils>, Module<FileUtils::Verbose>] fs
  def prepare(fs: nil)
    fs ||= fs(silent: true)

    directories.each { |dir| fs.mkdir_p(dir) }
    fs.cp(bundle_config.realpath, bundle_tmpdir.realpath.join('conf/config'))
    copy_lockfile(fs: fs)
    fs.rm_rf(bundle_tmpdir.join('home/config')) # ensure config is not present in home
  end

  # Ensure ``gems.locked ``(used as a volume)
  #
  # @param [Module<FileUtils>, Module<FileUtils::Verbose>] fs
  def copy_lockfile(fs: nil)
    fs ||= fs(silent: true)

    shell.pwd.join('gems.locked').then do |fp|
      [
        -> { fs.cp(fp, bundle_tmpdir.join('gems.locked')) },
        -> { fs.touch(bundle_tmpdir.join('gems.locked')) }
      ].fetch(fp.file? ? 0 : 1).call
    end
  end

  # rubocop:enable Naming/MethodParameterName

  # @return [::Aldine::Utils::BundleConfig]
  def bundle_config
    ::Aldine::Utils::BundleConfig.new(shell.pwd)
  end

  def bundle_tmpdir
    self.tmpdir.join(TMP_BUNDLE_PATH)
  end
end
