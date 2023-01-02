# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../erb_command'

# Responsible of witing files.
class Aldine::Cli::Base::ErbCommand::Output
  autoload(:FileUtils, 'fileutils')
  autoload(:Pathname, 'pathname')

  # @param [String] basepath
  # @param [String] name
  # @param [Array<String>, nil] tags
  # @param [Boolean] verbose
  def initialize(basepath, name, tags: nil, verbose: true)
    self.tap do
      self.basepath = basepath.freeze
      self.name = name.freeze
      self.tags = (tags || []).map(&:to_s).reject(&:empty?).freeze
      # noinspection RubySimplifyBooleanInspection
      self.verbose = !!verbose
    end.freeze
  end

  def verbose?
    self.verbose
  end

  def call(content)
    fs.mkdir_p(file.dirname)
    fs.touch(file)

    file.write(content)
  end

  protected

  # @type [String]
  attr_accessor :basepath

  # @type [String]
  attr_accessor :name

  # Words added to the file.
  #
  # @return [Array<String>]
  #
  # @see #file
  attr_accessor :tags

  # @type [Boolean]
  attr_accessor :verbose

  # File written during call.
  #
  # @return [Pathname]
  def file
    [basepath, "erb-#{name}"]
      .concat(tags)
      .concat(['tex'])
      .join('.')
      .then { |fp| Pathname.new(fp) }
  end

  # @return [Module<FileUtils::Verbose>, Module<FileUtils>]
  def fs
    verbose? ? FileUtils::Verbose : FileUtils
  end
end
