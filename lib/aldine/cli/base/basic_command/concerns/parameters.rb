# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../concerns'

# Parameters related concern.
#
# Allow to redefine a parameter.
module Aldine::Cli::Base::BasicCommand::Concerns::Parameters
  protected

  # @see Clamp::Parameter::Declaration#parameter
  #
  # @return [Clamp::Parameter::Definition, nil]
  def parameter(name, description, options = {}, &block)
    redefine_parameter(name, description, options) || super
  end

  # @api private
  # @return [Clamp::Parameter::Definition, nil]
  def redefine_parameter(name, description, options = {})
    nil.tap do
      definition = ::Clamp::Parameter::Definition.new(name, description, options)
      # @type [Clamp::Parameter::Definition] parameter
      (@parameters || []).each_with_index do |parameter, index|
        if parameter.attribute_name == definition.attribute_name
          return @parameters[index] = definition
        end
      end
    end
  end
end
