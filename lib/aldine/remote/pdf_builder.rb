# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

# PDF builder
#
# Filenames for TEX files: [LATEX_NAME].[TYPE].tex
class Aldine::Remote::PdfBuilder
  autoload(:Pathname, 'pathname')

  include(::Aldine::Concerns::SettingsAware)

  # @param [Symbol] type
  # @param [Hash{String => String]}, nil] env
  def initialize(type, env: nil)
    @type = type.to_sym
    @env = (env || {}).transform_keys(&:to_s).transform_values(&:to_s)
  end

  # @return [Pathname]
  def call
    output.tap { sequence.map(&:call) }
  end

  # @return [String]
  def jobname
    [settings.get('output_name'), type].join('.')
  end

  # @return [String]
  def filename
    [settings.get('latex_name'), type, 'tex'].join('.')
  end

  # @return [Pahname]
  def output
    Pathname.new("#{jobname}.pdf").expand_path
  end

  # noinspection RubyLiteralArrayInspection
  class << self
    def options
      ['-halt-on-error', '-interaction=batchmode', '-shell-escape']
    end
  end

  protected

  # @return [Hash{String => String}]
  attr_reader :env

  # @return [Hash]
  attr_reader :config

  # @return [Symbol]
  attr_reader :type

  # @return [Array<Shell::Coomand>]
  def sequence
    ['pdflatex'].concat(self.class.options).concat(["-jobname=#{jobname}", filename]).then do |cmd|
      [
        command(cmd),
        command(['makeindex', filename]),
        command(cmd),
      ]
    end
  end

  # @param [Array<String>] command
  def command(command)
    ::Aldine::Shell::Command.new(command, env: self.env)
  end
end
