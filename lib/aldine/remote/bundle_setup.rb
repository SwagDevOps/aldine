# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

# Install bundle realted files (using symlinks).
#
# Sample of use:
#
# ```
# Aldine::Remote::BundleSetup.new('/tmp/test_bundle', source_dir: "#{__dir__}/samples").call
# ```
class Aldine::Remote::BundleSetup < Aldine::Shell::Command
  autoload(:FileUtils, 'fileutils')
  autoload(:Pathname, 'pathname')

  def initialize(target_dir, source_dir: nil, env: {})
    self.target_dir = Pathname.new(target_dir)
    self.source_dir = Pathname.new(source_dir || ENV.fetch('WORKDIR'))

    super(arguments_builder.call, env: env)
  end

  def call
    fs.mkdir_p(target_dir).then { super }
  end

  protected

  # @return [Pathname]
  attr_accessor :target_dir

  # @return [Pathname]
  attr_accessor :source_dir

  # Get a builder providing arguments used to initialize command.
  #
  # @return [Proc]
  def arguments_builder
    lambda do
      %w[ln -sfr]
        .concat(files.map(&:to_path))
        .concat([target_dir.expand_path.to_s])
    end
  end

  # Get files (as absolute paths) in source dir to symlink.
  #
  # @return [Array<Pathname>]
  def files
    %w[gems.rb gems.locked .bundle]
      .map { |filename| source_dir.join(filename) }
      .concat([bundle_config.bundle_basedir])
      .map(&:realpath)
      .sort
  end

  # @return [Aldine::Utils::BundleConfig]
  def bundle_config
    ::Aldine::Utils::BundleConfig.new(source_dir)
  end

  # @return [Module<FileUtils>, Module<FileUtils::Verbose>]
  def fs
    silent? ? FileUtils : FileUtils::Verbose
  end
end
