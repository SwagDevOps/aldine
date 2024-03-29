# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../aldine'
autoload(:Clamp, 'clamp')

# Namespace module
module Aldine::Cli
  "#{__dir__}/cli".tap do |path|
    {
      App: :app,
      Erb: :erb,
      LegacyApp: :legacy_app, # @todo remove legacy app
      ErbChapters: :erb_chapters,
      ErbHyperrefSetup: :erb_hyperref_setup,
      ErbImageFull: :erb_image_full,
      Svg2Pdf: :svg2pdf,
    }.each { |k, v| autoload(k, "#{path}/#{v}") }
  end

  require('fileutils').then do
    ::FileUtils::Verbose.instance_variable_set(:@fileutils_output, $stderr)
  end

  # Namespace for commands
  module Commands
    # Module with classes/modules shared between several commands
    module Shared
      {
        FilesMatcher: :files_matcher,
        SvgConv: :svg_conv,
      }.each { |k, v| autoload(k, "#{__dir__}/cli/commands/shared/#{v}") }
    end

    # Module for concerns.
    module Concerns
      {
        ImageMatch: :image_match,
        InputYaml: :input_yaml,
        SvgConvert: :svg_convert,
      }.each { |k, v| autoload(k, "#{__dir__}/cli/commands/concerns/#{v}") }
    end
  end

  # Namespace for base (abstract) commands
  module Base
    "#{__dir__}/cli/base".tap do |path|
      {
        BaseCommand: :base_command,
        BasicCommand: :basic_command,
        ErbCommand: :erb_command,
        ErbImageCommand: :erb_image_command,
        OverridableCommand: :overridable_command,
      }.each { |k, v| autoload(k, "#{path}/#{v}") }
    end
  end

  # Base class for subcommands.
  #
  # @abstract
  class Command < ::Clamp::Command
    # @see https://github.com/mdub/clamp/blob/05bc13f7b484ae3e116c6f0de5a5e18280fa9ecc/README.md#allowing-options-after-parameters
    ::Clamp.allow_options_after_parameters = true
  end
end
