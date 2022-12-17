# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../docker'

# Provides a Hash of tmpdirs used by bundler in docker (with persistance on the host filesystem).
class Aldine::Local::Docker::BundleTmpDirsProvider
  # @api private
  TMP_BUNDLE_PATH = '.sys/bundle'

  # @param [Pathname, String] tmpdir
  #
  # @return [Hash{Symbol => Pathname}]
  def call(tmpdir:)
    Pathname.new(tmpdir).then do |tmp_path|
      self.class.__send__(:bundle_tmpdirs, tmp_path)
    end
  end

  class << self
    # @param [Pathname, String] tmpdir
    #
    # @return [Hash{Symbol => Pathname}]
    def call(tmpdir:)
      self.new.call(tmpdir: tmpdir)
    end

    protected

    # Get directories used for bundle share and persistance.
    #
    # @param [Pathname] tmpdir
    #
    # @return [Hash{Symbol => Pathname}]
    def bundle_tmpdirs(tmpdir)
      bundle_tmpdir = tmpdir.join(TMP_BUNDLE_PATH)

      %w[pack conf home]
        .map { |dir| [dir.to_sym, bundle_tmpdir.join(dir)] }
        .concat([[:base, bundle_tmpdir]]) # base (root) of bundle_tmpdir - is first
        .sort_by { |a| a.fetch(0) == :base ? '' : a.fetch(0).to_s }
        .to_h
    end
  end
end
