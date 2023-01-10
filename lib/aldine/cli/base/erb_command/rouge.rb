# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../erb_command'

# Responsible of highlighting code.
class Aldine::Cli::Base::ErbCommand::Rouge
  autoload(:Rouge, 'rouge')

  # @param [IO, Object, nil] output
  def initialize(output: $stdout)
    self.tap do
      self.output = output
    end.freeze
  end

  # @param [String] source
  def call(source)
    formatter.format(lexer.lex(source)).tap do |content|
      output&.write(content)
    end
  end

  protected

  # @return [IO, Object, nil]
  attr_accessor :output

  # @return [Rouge::Formatters::Formatter]
  def formatter
    Rouge::Formatters::Terminal256.new
  end

  # @return [Rouge::Lexers::TeX]
  def lexer
    Rouge::Lexers::TeX.new
  end
end
