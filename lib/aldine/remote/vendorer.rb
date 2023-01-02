# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../remote'

# Wrapper built on top of vendorer.
#
# Use a more declarative syntax based on YAML.
#
# Sample file:
#
# <code>
# ---
# vendor/assets/javascripts/jquery.min.js:
#   url: 'http://code.jquery.com/jquery-latest.min.js'
#   type: 'file'
#   vendor/plugins/parallel_tests:
#   url: 'https://github.com/grosser/parallel_tests.git'
# vendor/bash/bash-completion:
#   url: 'https://github.com/scop/bash-completion'
#   tag: '2.10'
# <code>
#
# @see https://github.com/grosser/vendorer
class Aldine::Remote::Vendorer
  autoload(:Pathname, 'pathname')
  autoload(:Vendorer, 'vendorer')
  # noinspection RubyLiteralArrayInspection,RubyResolve
  "#{__dir__}/vendorer".tap do |path|
    {
      Parser: :parser,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end

  # @param [Pathname, nil] path
  def initialize(path = nil)
    self.path = Pathname.new(path || Dir.pwd).realpath.freeze

    self.freeze
  end

  # @param [Symbol, nil] mode
  #
  # @return [Array<StandardError>]
  def call(mode: nil)
    {}.tap do |errors|
      self.init(mode: mode).then do |vendorer|
        parameters.map do |v|
          vendorer.public_send(*v)
        rescue RuntimeError => e
          errors[v] = e
        end
      end
      # Display errors (if any)
      errors.map { |k, e| error_fmt(e, k, output: $stderr) }
    end.values
  end

  # @return [Array<Hash{Symbol => Object}>]
  def payload
    file? ? Parser.new.call(file) : []
  end

  # @return [Pathname]
  def file
    self.path.join(self.filename)
  end

  # @return [Boolean]
  def file?
    file.file? and file.readable?
  end

  # @return [String]
  def filename
    'vendorer.yml'
  end

  # Get volume parameters for docker integration.
  #
  # @param [Pathname] pwd
  # @param [Pathname] dir
  #
  # @return [Array<String>]
  def volume_for(pwd, dir)
    return [] unless file?

    ['-v', "#{pwd.join(self.filename).realpath}:#{dir.join(self.filename)}:ro"]
  end

  protected

  # @type [Pathname]
  attr_accessor :path

  # Parameters for ``file`` and ``folder`` methods.
  #
  # @see Vendorer#file()
  # @see Vendorer#folder()
  #
  # @return [Array<Array>]
  def parameters
    self.payload.map do |h|
      [
        h.fetch(:type),
        Pathname.new(h.fetch(:path).to_s).then { |path| path.absolute? ? path : self.path.join(path) },
        h.fetch(:url)
      ].then do |params|
        h[:type] == 'folder' ? params.concat([h.fetch(:options)]) : params
      end
    end
  end

  # Instanciate an instance.
  #
  # @param [Symbol, nil] mode
  #
  # @return [Vendorer]
  def init(mode: nil)
    Vendorer.new({ update: mode&.to_sym == :update })
  end

  # Format (and display on given output) an errors with paramaters.
  #
  # @param [StandardError] error
  # @param [Array] params
  # @param [IO, StringIO, nil] output
  #
  # @return [String]
  def error_fmt(error, params, output: nil)
    ('failed: %<url>s (%<error_type>s)' % {
      error_type: error.class,
      url: params[1],
    }).tap { |v| output&.puts(v) }
  end
end
