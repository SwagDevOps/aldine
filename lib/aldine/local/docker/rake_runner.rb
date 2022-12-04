# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Wrapper built around rake execution.
class Aldine::Local::Docker::RakeRunner
  autoload(:Pathname, 'pathname')

  # @api private
  DEFAULT_RAKEFILE = ::Aldine::Remote::RESOURCES_DIR.join('rake/Rakefile').realpath.freeze

  # @api private
  HIDDEN_RAKEFILE = '.rake.rb'

  # @param [Proc] runner
  def initialize(runner)
    self.tap do
      self.runner = runner.dup.freeze
      self.memo = {}
    end.freeze
  end

  # @param [String] task
  def call(task, **options)
    command_for(task, path: options[:path].to_s).then do |command|
      self.runner.call(command, **options)
    end
  end

  protected

  # @return [Proc]
  attr_accessor :runner

  # @return [Hash]
  attr_accessor :memo

  # @param [String] task
  #
  # @return [Array<String>]
  def command_for(task, path:)
    %w[bundle exec rake]
      .concat([task])
      .concat(['-NGf', rakefile(path) || HIDDEN_RAKEFILE])
      .map(&:to_s)
  end

  # Ensure rakefile exists.
  #
  # @param [String] path
  #
  # @return [String]
  def rakefile(path)
    default_rakefile_for(path) || lambda do
      HIDDEN_RAKEFILE.tap do |filename|
        Pathname.new(Dir.pwd)
                .join(path, filename)
                .then { |fp| fp.write(DEFAULT_RAKEFILE.read) }
      end
    end.call
  end

  # @see https://github.com/ruby/rake/blob/01577583712fb8d871ded8fac1bd76dafaa4416c/lib/rake/application.rb#L41
  #
  # @return [Array<String>]
  def default_rakefiles
    %w[rakefile Rakefile rakefile.rb Rakefile.rb]
  end

  # @return [Boolean]
  def default_rakefile_for?(path)
    !default_rakefile_for(path).nil?
  end

  # @return [String, nil]
  def default_rakefile_for(path)
    store = self.memo[:default_rakefile] ||= {}

    {
      true => -> { store[path] },
      false => lambda do
        default_rakefiles
          .map { |filename| rakefile_check(path, filename).call }
          .compact.first
      end
    }.then { |retrievers| store[path] = retrievers[store.key?(path)].call }
  end

  # Build a checker checking given file in given path (in a docker context).
  #
  # Result of the check is ``nill`` when file does not exist, filepath otherwise.
  #
  # @param [String] path
  # @param [String] filename
  #
  # @return [Proc]
  def rakefile_check(path, filename)
    Pathname
      .new(path)
      .join(filename)
      .then { |fp| ['test', '-f', fp.relative_path_from(path).to_path] }
      # @formatter:off
      .then do |command|
        lambda do
          runner.call(command, path: path, exception: false, silent: true).success? ? command.last : nil
        end
      end
    # @formatter:on
  end
end
