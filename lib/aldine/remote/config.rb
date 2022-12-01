# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

# Provide config based on evironment variables
class Aldine::Remote::Config < ::Hash
  def initialize
    super().tap do
      self.class.__send__(:defaults).each { |k, v| self[k] = v }
    end
  end

  class << self
    # @param [String, Symbol] key
    #
    # @return [Object]
    def [](key)
      self.new[key]
    end

    protected

    include(::Aldine::Concerns::SettingsAware)

    # Default values.
    #
    # @api private
    #
    # @todo add watch_exclude to settings
    def defaults
      {
        tex_dir: settings.get('directories.tmp'), # 'tmp'
        src_dir: settings.get('directories.src'),
        out_dir: settings.get('directories.out'),
        output_name: settings.get('output_name'),
        latex_name: settings.get('latex_name'),
        watch_exclude: '^.*/(\..+|(M|m)akefile|.*(\.mk|~))$',
      }
    end
  end
end
