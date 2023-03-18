# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../svg_conv'

# Describe a cache with simple fs operations.
class Aldine::Cli::Commands::Shared::SvgConv::Cache
  autoload(:Shellwords, 'shellwords')
  autoload(:JSON, 'json')

  include(::Aldine::Concerns::HasLocalFileSystem)

  # @param [Pathname, String] path
  def initialize(path, debug: true)
    self.tap do
      self.path = Pathname.new(path)
      # noinspection RubySimplifyBooleanInspection
      self.debug = !!debug
    end
  end

  def dump
    decode(self.path)
  end

  def data
    dump&.data
  end

  def store(payload = {})
    write(self.path, (payload || {}).to_h)
  end

  protected

  # @return [Pathname]
  attr_accessor :path

  # @return [Boolean]
  attr_accessor :debug

  alias debug? debug

  # rubocop:disable Metrics/AbcSize

  # Decode cache file (from json).
  #
  # @param {Pathname} cache_file
  #
  # @return [Struct]
  def decode(cache_file)
    return nil unless cache_file.file? and cache_file.readable?

    warn(Shellwords.join(['json', '-d', cache_file.to_s])) if debug? # inspired by base64 command

    Struct.new(:path, :target, :checksum, :data, keyword_init: true).yield_self do |struct|
      JSON.parse(cache_file.read).transform_keys(&:to_sym).yield_self do |h|
        h[:data] = nil unless h[:checksum].eql?(self.checksum) # nullify data when checksum mismatch

        struct.new(**h.merge({ data: [h.fetch(:data)].flatten.join }))
      end
    end
  rescue ::RuntimeError => e
    warn(e.message).then { nil }
  end
  # rubocop:enable Metrics/AbcSize

  # @param [Pathname] cache_file
  # @param [Object] payload
  #
  # @return [Integer]
  def write(cache_file, payload)
    self.fs(silent: !debug?).tap do |fs|
      fs.mkdir_p(cache_file.dirname) unless cache_file.dirname.directory?
      fs.touch(cache_file) unless cache_file.file?
    end

    cache_file.write(JSON.pretty_generate(payload))
  end
end
