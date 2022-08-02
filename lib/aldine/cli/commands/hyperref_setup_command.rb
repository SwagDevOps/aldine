# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# Produce hyperref markup.
#
# Sample of use:
#
# ```latex
# \def\hyperrefSetup(#1) {
#  \immediate\write18{erb-hyperref_setup #1}
#  \input{#1.erb-hyperref_setup}
# }
# ```
class Aldine::Cli::Commands::HyperrefSetupCommand < Aldine::Cli::Base::ErbCommand
  include ::Aldine::Cli::Commands::Concerns::InputYaml

  # File used to provide hyperref setup.
  #
  # @return [Pathname]
  def input_file
    Pathname.new("#{source.to_s.gsub(/\.yml$/, '')}.yml").freeze
  end

  def output_basepath
    input_file.expand_path.dirname.join(input_file.basename('.*')).to_path
  end

  protected

  def variables_builder
    lambda do
      {
        setup: self.input_yaml,
      }
    end
  end
end
