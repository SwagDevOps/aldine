# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../erb_command'

# Template on top of ERB.
class Aldine::Cli::Base::ErbCommand::Template
  autoload(:ERB, 'erb')
  autoload(:Pathname, 'pathname')

  # @return [String]
  attr_reader :name

  # @param [String] name
  # @param [Boolean] debug
  def initialize(name, debug: true)
    self.tap do
      self.name = name.freeze
      # noinspection RubySimplifyBooleanInspection
      self.debug = !!debug
    end.freeze
  end

  # Render template.
  #
  # @return [String]
  def call(variables)
    bind(variables).then { |b| erb.result(b) }
  end

  # Denotes debug messages SHOULD appear.
  #
  # @return [Boolean]
  def debug?
    !!self.debug
  end

  protected

  # @type [String]
  attr_writer :name

  # @type [Boolean]
  attr_accessor :debug

  def erb
    # @see https://github.com/rubocop/rubocop/pull/5845#issuecomment-1008348049
    ERB.new(self.read.to_s, trim_mode: '>')
  end

  # Read template file.
  #
  # @return [String, nil]
  def read
    # @type [Pathname] file
    # rubocop:disable Style/SymbolProc
    with_file { |file| file.read }
    # rubocop:enable Style/SymbolProc
  end

  # Make binding for ERB rendering and variables lookup.
  #
  # @param [Hash{Symbol => Object}] variables
  #
  # @return [Binding]
  def bind(variables)
    { env: ENV.to_h.freeze }
      .merge(variables)
      .then { |vars| Struct.new(*vars.keys).new(*vars.values) }
      .then { |container| container.freeze.instance_eval { binding } }
  end

  # Get template file path.
  #
  # @return [Pathname, nil]
  def file
    paths
      .map { |path| path.join("#{name}.tex.erb") }
      .keep_if { |fp| fp.file? and fp.readable? }
      .first
  end

  # Paths to stored template files.
  #
  # @return [Array<Pathname>]
  def paths
    [
      Pathname.new(__dir__).join('../..', 'erb').realpath
    ]
  end

  # Execute given block only when file exists.
  #
  # @yieldparam [Pathname] file
  #
  # @return [String, nil]
  def with_file(&block)
    file.nil? ? missing_file : block.call(file)
  end

  # Behavior for missing file.
  #
  # Defaults to print a message on STDERR.
  #
  # @return [NilClass]
  def missing_file
    nil.tap do
      warn("Can not read template for #{name.inspect}") if debug?
    end
  end
end
