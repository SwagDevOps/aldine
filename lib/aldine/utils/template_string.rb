# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../utils'

# Template string, using native ruby interpolation, from a struct context.
class Aldine::Utils::TemplateString
  # @param [String] template
  def initialize(template)
    self.template = template
  end

  # @param [Hash{String, Symbol => Object}] variables
  #
  # @return [String]
  def render(variables)
    struct(variables).instance_eval(renderable, __FILE__, __LINE__)
  end

  alias call render

  protected

  # @type [String]
  attr_accessor :template

  # @param [String]
  def renderable
    template.gsub(/"/, '\"').then { |q| %("#{q}") }
  end

  # Make a ``Struct`` from given payload.
  #
  # @param [Hash{String, Symbol => Object}] payload
  #
  # @return [Struct]
  def struct(payload)
    ::Struct.new(*payload.keys).new(*payload.values)
  end
end
