# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../../app'

# Wrapper build on top of convert. Convert svg to pdf.
#
# Output is cached and compared by original file md5sum.
class Aldine::Cli::Commands::Shared::SvgConv # rubocop:disable Metrics/ClassLength
  autoload(:Digest, 'digest')
  autoload(:Pathname, 'pathname')
  autoload(:FileUtils, 'fileutils')
  autoload(:Base64, 'base64')
  autoload(:JSON, 'json')
  autoload(:Shellwords, 'shellwords')

  def initialize(debug: true, tmpdir: nil, cache: true)
    self.tap do
      # noinspection RubySimplifyBooleanInspection
      self.debug = !!debug
      # noinspection RubySimplifyBooleanInspection
      self.cache = !!cache
      self.tmpdir = tmpdir || lambda do
        require 'tmpdir'

        Pathname.new(Dir.tmpdir).expand_path
      end.call
    end.freeze
  end

  def debug?
    !!self.debug
  end

  # Denotes cache will be used (when present) and generated.
  #
  # @return [Boolean]
  def cache?
    !!self.cache
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

  # Describe target.
  #
  # @param [Pathname] origin
  #
  # @return [Struct]
  def target(origin)
    {
      origin: origin,
      output: origin.dirname.join("#{origin.basename('.*')}.pdf"),
      cache_file: self.cache_file_for(origin),
      debug?: self.debug,
    }.yield_self do |payload|
      Struct.new(:origin, :output, :cache_file, :debug?, keyword_init: true).new(**payload).tap do |instance|
        instance.singleton_class.tap do |klass|
          klass.define_method(:to_s) { Pathname.new(origin.to_s).relative_path_from(Dir.pwd).basename('.*').to_s }
          klass.define_method(:checksum) do
            warn(Shellwords.join(['md5sum', origin.to_s])) if debug?

            Digest::MD5.hexdigest(origin.read)
          end
          klass.define_method(:cached?) { !cache.nil? and cache.checksum == checksum }
          klass.define_method(:cache) do
            return nil unless cache_file.file?

            warn(Shellwords.join(['json', '-d', cache_file.to_s])) if debug? # inspired by base64 command
            Struct.new(:path, :target, :checksum, :data, keyword_init: true).yield_self do |struct|
              JSON.parse(cache_file.read).transform_keys(&:to_sym).yield_self do |h|
                struct.new(**h.merge({ data: [h.fetch(:data)].flatten.join }))
              end
            end
          end
        end
      end
    end
  end

  # Convert given file.
  #
  # @param [Pathname] origin
  #
  # @return [Pathname] as output file
  def call(origin)
    target = self.target(origin)

    if self.cache? && target.cached?
      target.output.tap do |output_file|
        output_file.write(Base64.decode64(target.cache.data))

        return output_file
      end
    end

    convert(target).tap do |output_file|
      {
        path: target.cache_file.to_s,
        target: target.to_s,
        checksum: target.checksum,
        data: Base64.encode64(output_file.read).lines.map(&:strip),
      }.then do |payload|
        write_cache(target.cache_file, payload)
      end
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  protected

  # @api private
  #
  # @return [Boolean]
  attr_accessor :debug

  # @return [Pathname]
  attr_accessor :tmpdir

  # @api private
  #
  # @return [Boolean]
  attr_accessor :cache

  def convert_command_builder
    lambda do |input_file, output_file|
      # ['rsvg-convert', '-f', 'pdf', '-o', output_file.to_s, input_file.to_s]
      ['cairosvg', '-d', '300', '-u', input_file.to_s, '-o', output_file.to_s]
    end
  end

  # @param [Struct] target
  #
  # @return [Pathname]
  def convert(target)
    target.output.tap do |output_file|
      convert_command_builder.call(target.origin, output_file).tap do |command|
        warn(Shellwords.join(command))

        unless system(*command)
          raise 'Can not convert %s' % target.origin.to_s.inspect
        end
      end
    end
  end

  # Gets cache file path related to given path.
  #
  # @param [String, Pathname] filepath
  #
  # @return [Pathname]
  def cache_file_for(filepath)
    # noinspection RubyMismatchedReturnType
    [
      Pathname.new(__FILE__).basename('.*').to_s,
      Digest::SHA1.hexdigest(filepath.to_s),
      'json'
    ].then { |parts| tmpdir.join(parts.join('.')) }
  end

  # @param [Pathname] cache_file
  # @param [Hash] payload
  #
  # @return [FalseClass, Integer]
  def write_cache(cache_file, payload)
    return false unless cache?

    fs.mkdir_p(cache_file.dirname)
    fs.touch(cache_file)
    cache_file.write(JSON.pretty_generate(payload))
  end

  # @return [Module<FileUtils>, Module<FileUtils::Verbose>]
  def fs
    debug? ? FileUtils::Verbose : FileUtils
  end
end
