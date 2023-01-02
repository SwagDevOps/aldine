# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../shell'

# @abstract
class Aldine::Shell::Command
  autoload(:Shellwords, 'shellwords')

  # Mutex used to ensure atomicity on system calls
  #
  # @api private
  SYSTEM_LOCK = Mutex.new

  # @param [Array<String>] arguments
  # @param [Hash{ String => String }] env
  def initialize(arguments, env: {})
    super().tap do
      @arguments = arguments.clone.map(&:freeze).freeze
      @env = env.clone.map { |k, v| [k.freeze, v.freeze] }.to_h.freeze

      self.silent = @silent.nil? ? false : @silent
    end
  end

  # @return [Boolean]
  def silent?
    !!self.silent
  end

  # @return [Array<String>]
  def to_a
    arguments.clone.dup
  end

  # @return [Hash{String => String}]
  def env
    @env.clone.dup
  end

  def to_s
    Shellwords.join(self.to_a)
  end

  alias inspect to_a

  # Executes command… in a subshell.
  #
  # @return [Process::Status]
  #
  # @see https://www.bigbinary.com/blog/ruby-2-6-added-option-to-raise-exception-in-kernel-system
  def call(exception: true)
    inner_call do
      SYSTEM_LOCK.synchronize do
        ::Kernel.system(*system_args).tap do |res|
          if exception and res == false
            raise ::Aldine::Shell::CommandError.new(self.to_a, status: child_status)
          end
        end
      end
    end
  end

  protected

  # @return [Array<String>]
  attr_reader :arguments

  # @return [Boolean]
  attr_accessor :silent

  def system_args
    [env, *self.to_a]
  end

  def warn(message)
    ::Kernel.warn(message)
  end

  # @return [Process::Status]
  def inner_call(&block)
    warn(self.to_s) unless silent?
    block.call.then { child_status }
  end

  # @return [Process::Status]
  def child_status
    $CHILD_STATUS
  end
end
