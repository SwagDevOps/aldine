# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../aldine'

# Load dotenv files + add validation
#
# @see https://github.com/fastruby/dotenv_validator
class Aldine::DotenvLoader
  autoload(:Pathname, 'pathname')

  # @api private
  ENV_FILES = %w[.env.local .env].freeze

  # @return [Pathname]
  attr_reader :base_dir

  # @param [Array<String>|nil] files
  def initialize(base_dir, files = nil)
    self.base_dir = Pathname.new(base_dir).realpath
    @files = (Array(files).empty? ? ENV_FILES : Array(files).map(&:to_s)).freeze
  end

  # Load environment variables from ``.env`` file into ``ENV``.
  #
  # @return [Hash{String => String}]
  def call(&block)
    # noinspection RubyResolve,RubyMismatchedReturnType
    dotenv.load(*self.files).tap do
      validator.check!
      block&.call
    end
  end

  # @return [Array<String>]
  def files
    @files.dup.map { |fp| Pathname.new(fp).expand_path.to_s }.concat([sample.to_s])
  end

  # @return [Pathname]
  def sample
    Pathname.pwd.join('.env.sample').then do |env_sample|
      return env_sample.exist? ? env_sample : base_dir.join('.env.sample')
    end
  end

  protected

  attr_writer :base_dir

  # @return [Module<DotenvValidator>]
  def validator
    (require 'dotenv_validator').then { ::DotenvValidator }
  end

  # @return [Module<Dotenv>]
  def dotenv
    (require 'dotenv').then { ::Dotenv }
  end
end
