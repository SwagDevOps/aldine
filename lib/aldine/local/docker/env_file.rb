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
# Variables are read from envfile ``docker.env``
# and passed through the command line of the docker process.
#
# @see Aldine::Local::Docker
class Aldine::Local::Docker::EnvFile
  autoload(:Dotenv, 'dotenv')
  autoload(:Pathname, 'pathname')

  # Initialize an env-file parser.
  #
  # @param [String, nil] file File to be parsed
  # @param [Hash{String => String}] defaults Default values for missing env variables.
  def initialize(file = nil, defaults: {})
    self.env = ENV.to_h.freeze
    self.file = file
    self.defaults = (defaults || {}).transform_keys(&:to_s)
  end

  # Read, parse and mix current environment varaibles with the declarations found in the envfile.
  #
  # Environment variables have higher priority on variables defined in the env-file.
  #
  # @return [Hash{String => String}]
  def parse
    read.then do |parsed|
      env.keep_if { |key, _| parsed.keys.include?(key) }
         .then { |env| parsed.merge(env) }
    end
  end

  def fetch(...)
    to_h.fetch(...)
  end

  # Env parameters for docker command.
  #
  # @see Aldine::Local::Docker
  #
  # @return [Array<String>]
  def arguments
    [].tap do |result|
      parse
        .map { |k, v| ['-e', "#{k}=#{v}"] }
        .each { |args| result.concat(args) }
    end
  end

  alias to_ary arguments

  alias to_a arguments

  alias to_h parse

  alias to_hash parse

  # @return [String]
  def to_str
    self.file.to_path
  end

  protected

  # @type [Hash{String => String}]
  attr_writer :env

  # File read.
  #
  # @return [Pathname]
  attr_reader :file

  # Default values for missing env variables.
  #
  # @return [Hash{String => String}]
  attr_accessor :defaults

  # Read the envfile.
  #
  # @return [Hash{String => String}]
  def read
    Dotenv
      .parse(file.to_path)
      .map { |k, v| [k.to_s, v.to_s] }
      .to_h
      .then { |parsed| defaults.merge(parsed) }
      .sort
      .to_h
  end

  # @return [Hash{String => String}]
  def env
    @env.dup
  end

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
