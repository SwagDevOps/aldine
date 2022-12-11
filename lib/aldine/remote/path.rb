# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

autoload(:Pathname, 'pathname')

# Absolute path (configured inside workdir).
class Aldine::Remote::Path < Pathname
  include ::Aldine::Concerns::SettingsAware

  def initialize(*)
    'container.workdir'.then do |key|
      settings.get(key).tap do |v|
        raise "Get nil value for #{key.inspect}" if v.nil?
      end
    end.then { |workdir| super(workdir) }
  end

  class << self
    include ::Aldine::Concerns::SettingsAware

    # @return [self, Pathname]
    def call(key = nil)
      return self.new if key.nil?

      # @type [Hash{Symbol => String}] directories
      settings.get('directories', {}).then do |directories|
        directories.fetch(key.to_sym).then { |v| self.new.join(v) }
      end
    end
  end
end
