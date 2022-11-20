# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../local'

# Tex project related methods.
module Aldine::Local::Tex
  class << self
    include(::Aldine::Concerns::SettingsAware)

    # @return [String]
    def project_name
      settings.get('output_name').tap do |value|
        if value.to_s.empty?
          # rubocop:disable Style/RedundantException
          raise RuntimeError, 'Output name can not be nil'
          # rubocop:enable Style/RedundantException
        end
      end.to_s
    end

    alias output_name project_name
  end
end
