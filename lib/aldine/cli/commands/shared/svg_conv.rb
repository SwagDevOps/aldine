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
class Aldine::Cli::Commands::Shared::SvgConv
  autoload(:Pathname, 'pathname')
  autoload(:Base64, 'base64')

  include(::Aldine::Concerns::DefineTmpdir)
  include(::Aldine::Concerns::HasLocalShell)
  include(::Aldine::Concerns::HasLocalFileSystem)

  {
    Cache: :cache,
    Target: :target,
  }.each { |k, v| autoload(k, "#{__dir__}/svg_conv/#{v}") }

  def initialize(debug: true, tmpdir: nil, cache: true)
    self.define_tmpdir(:tmpdir, tmpdir: tmpdir).tap do
      # noinspection RubySimplifyBooleanInspection
      self.debug = !!debug
      # noinspection RubySimplifyBooleanInspection
      self.cache = !!cache
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

  # Convert given file.
  #
  # @param [Pathname] origin
  #
  # @return [Pathname] as output file
  def call(origin)
    target = self.target(origin)

    if self.cache? && (data = target.cache.data)
      return target.output.tap do |file|
        fs(silent: !debug?).touch(file.to_s)
        file.write(Base64.decode64(data))
      end
    end

    convert(target).tap { target.cache.store }
  end

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

  # Describe target.
  #
  # @param [Pathname] origin
  #
  # @return [Target]
  def target(origin)
    Target.new(origin, tmpdir: tmpdir, debug: debug?)
  end

  # @return [Proc]
  def convert_command_builder
    # @type [Target] target
    lambda do |target|
      # ['rsvg-convert', '-f', 'pdf', '-o', output_file.to_s, input_file.to_s]
      ['cairosvg', '-d', '300', '-u', target.origin.to_s, '-o', target.output.to_s]
    end
  end

  # Convert given target (from ``svg`` to ``pdf``)
  #
  # @param [Target] target
  #
  # @return [Pathname]
  def convert(target)
    target.output.tap do
      convert_command_builder.call(target).tap { |command| shell.sh(*command) }
    end
  end
end
