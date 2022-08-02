# frozen_string_literal: true

# Copyright (C) 2021-2022 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../shell'

# Colorize shell outputs.
class Aldine::Shell::Chalk
  FG_COLORS = {
    default: 38,
    black: 30,
    red: 31,
    light_red: '1;31',
    green: 32,
    light_green: '1;32',
    brown: 33,
    blue: 34,
    light_blue: '1;34',
    purple: 35,
    light_purple: '1;35',
    cyan: 36,
    light_cyan: '1;36',
    gray: 37,
    dark_gray: '1;30',
    yellow: 33,
    light_yellow: '1;33',
    white: '1;37'
  }.map { |k, v| [k.to_sym, v.to_s.freeze] }.to_h.freeze

  BG_COLORS = {
    default: 0,
    black: 40,
    red: 41,
    green: 42,
    brown: 43,
    blue: 44,
    purple: 45,
    cyan: 46,
    gray: 47,
    dark_gray: 100,
    light_red: 101,
    light_green: 102,
    yellow: 103,
    light_blue: 104,
    light_purple: 105,
    light_cyan: 106,
    white: 107
  }.map { |k, v| [k.to_sym, v.to_s.freeze] }.to_h.freeze

  OPTIONS = {
    bold: 1,
    dim: 2,
    italic: 3,
    underline: 4,
    reverse: 7,
    hidden: 8
  }.map { |k, v| [k.to_sym, v.to_s.freeze] }.to_h.freeze

  class << self
    def warn(message, **kwargs)
      instance.warn(message, **kwargs)
    end

    protected

    def instance
      self.new
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Naming/MethodParameterName

  def call(text, fg: nil, bg: nil, options: nil, stream: nil)
    options = [options].flatten.compact.map { |v| OPTIONS.fetch(v.to_sym) }

    {
      fg: FG_COLORS.fetch((fg || :default).to_sym),
      bg: BG_COLORS.fetch((bg || :default).to_sym),
    }.then do |codes|
      bg = codes.fetch(:bg)
      fg = codes.fetch(:fg)

      if stream.nil? or (stream.respond_to?(:tty?) and stream.tty?)
        "#{esc}#{bg};#{options.join(';')};#{fg}m#{text}#{esc}0m".squeeze(';')
      else
        text
      end
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Naming/MethodParameterName

  def warn(message, **kwargs)
    self.call(message, **kwargs.merge({ stream: $stderr })).then { |s| ::Kernel.warn(s) }
  end

  protected

  def esc
    "\033["
  end
end
