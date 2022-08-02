# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../erb_command'

# Describe expected output type.
#
# Available values are:
#
# * ``file`` write output to a file (default)
# * ``term`` terminal output
# * ``both`` SHOULD output to terminal and file, at once.
# * ``none`` SHOULD disable all outputs
class Aldine::Cli::Base::ErbCommand::OutputType
  # @api private
  TYPES = [:file, :term, :both, :none].freeze

  class << self
    # Get all available types.
    #
    # @return [Array<Symbol>]
    def types
      TYPES
    end

    # Get default output type.
    #
    # @return [Symbol]
    def default
      types.fetch(0)
    end
  end

  # @param [String, Symbol] type
  def initialize(type)
    self.tap do
      (type || default).to_sym.tap do |given_type|
        # @todo raise exception (abort) when given type is not supported
        self.type = self.class.types.include?(given_type) ? given_type : default
      end
    end.freeze
  end

  # @return [Symbol]
  def to_sym
    self.type
  end

  # @return [Boolean]
  def term?
    [:both, :term].include?(self.to_sym)
  end

  # @return [Boolean]
  def file?
    [:both, :file].include?(self.to_sym)
  end

  # @return [Boolean]
  def disabled?
    [:none].include?(self.to_sym)
  end

  # @return [Boolean]
  def default?
    self.to_sym == self.default
  end

  protected

  # @type [Symbol]
  attr_accessor :type

  # @return [Symbol]
  def default
    self.class.default
  end
end
