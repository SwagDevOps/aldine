# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Envfile for the docker environment.
#
# Variables are set on the command line.
#
# @see Aldine::Local::Docker
class Aldine::Local::Docker::EnvFile
  autoload(:Dotenv, 'dotenv')
  autoload(:Pathname, 'pathname')

  def initialize(file = nil, defaults: {})
    self.file = file
    self.defaults = (defaults || {}).transform_keys(&:to_s)
  end

  # @return {Hash{String => String}}
  def parse
    Dotenv.parse(file.to_path).to_h.map { |k, v| [k.to_s, v.to_s] }.to_h
  end

  # Env parameters for docker command.
  #
  # @see Aldine::Local::Docker
  #
  # @return [Array<String>]
  def arguments
    [].tap do |result|
      (defaults || {})
        .transform_keys(&:to_s)
        .merge(self.parse)
        .sort
        .to_h
        .map { |k, v| ['-e', "#{k}=#{v}"] }
        .each { |args| result.concat(args) }
    end
  end

  alias to_ary arguments

  alias to_hash parse

  # @return [String]
  def to_str
    self.file.to_path
  end

  protected

  # File read.
  #
  # @return [Pathname]
  attr_reader :file

  # Default values for missing env variables.
  #
  # @return [Hash{String => String}]
  attr_accessor :defaults

  # @api private
  #
  # @param [String, nil] file
  #
  # @return [Pathname]
  def file=(file)
    # noinspection RubyMismatchedArgumentType
    @file = file ? Pathname.new(file).expand_path : default_file
  end

  # @api private
  #
  # @return [Pathname]
  def default_file
    Pathname.new(Dir.pwd).join('docker.env')
  end
end
