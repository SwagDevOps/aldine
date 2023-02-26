# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../erb_command'

# Responsible of witing files onto filesystem.
class Aldine::Cli::Base::ErbCommand::Output
  autoload(:FileUtils, 'fileutils')
  autoload(:Pathname, 'pathname')

  include(::Aldine::Concerns::HasLocalFileSystem)

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

  # Write given given content onto filesystem.
  #
  # @return [Integer]
  def call(content)
    self.file.then do |file|
      self.fs(silent: !self.verbose?).then do |fs|
        fs.mkdir_p(file.dirname) unless file.dirname.directory?
        fs.touch(file) unless file.exist?
      end

      file.write(content)
    end
  end

  # Denote output is run with verbose file operations (``FileUtils``).
  #
  # @see #fs
  #
  # @return [Boolean]
  def verbose?
    self.verbose
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
    [basepath]
      .concat(tags)
      .concat(["erb-#{name}", 'tex'])
      .join('.')
      .then { |fp| Pathname.new(fp) }
  end
end
