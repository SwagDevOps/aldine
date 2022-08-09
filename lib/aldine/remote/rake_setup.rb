# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

# Install rake related files (using copy).
#
# Sample of use:
#
# ```
# Aldine::Remote::RakeSetup.new('/tmp/test_bundle').call
# ```
class Aldine::Remote::RakeSetup
  autoload(:FileUtils, 'fileutils')
  autoload(:Pathname, 'pathname')

  # @param [String] target_dir
  # @param [String] source_dir
  # @param [Boolean] debug
  def initialize(target_dir, source_dir: nil, debug: false)
    self.target_dir = Pathname.new(target_dir)
    self.source_dir = source_dir ? Pathname.new(source_dir) : ::Aldine::Remote::RESOURCES_DIR.join('rake')
    # noinspection RubySimplifyBooleanInspection
    self.debug = !!debug
  end

  # @return [Boolean]
  def call
    true.tap do
      files.each { |fp| copy_file(fp) }
    end
  end

  # @return [Boolean]
  def debug?
    self.debug
  end

  protected

  # @return [Pathname]
  attr_accessor :target_dir

  # @return [Pathname]
  attr_accessor :source_dir

  # @return [Boolean]
  attr_accessor :debug

  # Get files (as absolute paths) in source dir to copy.
  #
  # @return [Array<Pathname>]
  def files
    %w[Rakefile]
      .map { |filename| source_dir.join(filename) }
      .map(&:realpath)
      .sort
  end

  # @return [Module<FileUtils>, Module<FileUtils::Verbose>]
  def fs
    debug? ? FileUtils::Verbose : FileUtils
  end

  # @param [Pathname] file
  #
  # @return [String]
  def copy_file(file)
    file.relative_path_from(source_dir).to_path.gsub(%r{^\./+}, '').tap do |relative_path|
      target_dir.join(relative_path).tap do |copy_file|
        unless copy_file.exist?
          fs.mkdir_p(copy_file.dirname.to_path) unless copy_file.dirname.exist?

          fs.cp(file.to_path, copy_file.to_path)
        end
      end
    end
  end
end
