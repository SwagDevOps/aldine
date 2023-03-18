# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../svg_conv'

# Describe the target for converions based on given origin.
class Aldine::Cli::Commands::Shared::SvgConv::Target
  autoload(:Base64, 'base64')
  autoload(:JSON, 'json')
  autoload(:Pathname, 'pathname')
  autoload(:Shellwords, 'shellwords')
  autoload(:Digest, 'digest')

  include(::Aldine::Concerns::DefineTmpdir)

  # @return [Pathname]
  attr_reader :origin

  # @param [Pathname] origin
  # @param [Symbol] prefix
  # @param [Pathname, String, nil] tmpdir
  # @param [Boolean] debug
  def initialize(origin, prefix: :svg_conv, tmpdir: nil, debug: true)
    define_tmpdir(:tmpdir, tmpdir: tmpdir).tap do
      self.origin = origin.expand_path.freeze
      self.prefix = prefix.to_sym
      # noinspection RubySimplifyBooleanInspection
      self.debug = !!debug
    end
  end

  # @return [Pathname]
  def expand_path
    Pathname.new(self.to_s).expand_path
  end

  def to_s
    Pathname.new(origin.to_s).relative_path_from(Dir.pwd).to_s
  end

  # Get a cache.
  #
  # @return [Aldine::Cli::Commands::Shared::SvgConv::Cache]
  def cache
    ::Aldine::Cli::Commands::Shared::SvgConv::Cache.new(cache_file, debug: debug?).tap do |instance|
      -> { self.payload }.then do |f|
        instance.define_singleton_method(:store) do |payload = {}|
          # @type [Aldine::Cli::Commands::Shared::SvgConv::Cache] instance
          payload.merge(f.call).then { |data| instance.__send__(:write, self.path, data) }
        end
        instance.define_singleton_method(:checksum) { f.call.fetch(:checksum) }
      end
    end
  end

  # @return [Pathname]
  def output
    origin.dirname.join("#{origin.basename('.*')}.pdf")
  end

  # @return [Boolean]
  def debug?
    self.debug
  end

  # Get checksum from origin.
  #
  # @return [String]
  def checksum
    warn(Shellwords.join(['md5sum', origin.to_s])) if debug?

    Digest::MD5.hexdigest(origin.read)
  end

  protected

  # @return [Pathname]
  attr_writer :origin

  # @return [Boolean]
  attr_accessor :debug

  # @return [Pathname]
  attr_accessor :tmpdir

  # @return [Symbol]
  attr_accessor :prefix

  # Use ``SHA1`` to generate path to the cache.
  #
  # @return [Pathname]
  def cache_file
    Digest::SHA1.hexdigest(origin.to_s).then do |path_sum|
      tmpdir.join(['svg_conv', path_sum, 'json'].join('.'))
    end
  end

  # Get (base) payload used by the cache.
  #
  # @return [Hash{Symbol => Object}]
  def payload
    {
      path: self.cache_file.to_s,
      target: self.to_s,
      checksum: self.checksum,
      data: self.output.file? ? Base64.encode64(self.output.read).lines.map(&:strip) : nil,
    }
  end
end
