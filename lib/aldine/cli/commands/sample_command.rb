# frozen_string_literal: true

# Copyright (C) 2021-2023 Dimitri Arrigoni <dimitri@arrigoni.me>
# License LGPLv3+: GNU Lesser General Public License version 3 or later
# You may obtain a copy of the License at http://www.gnu.org/licenses/lgpl.txt.
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an “AS IS” BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require_relative '../app'

# A sample command.
#
# This is a simple sample command.
# Illustrates basic features. Produces random quotes in a HP Lovecraft's style.
class Aldine::Cli::Commands::SampleCommand < Aldine::Cli::Base::ErbCommand
  autoload(:Faker, 'faker')
  autoload(:Digest, 'digest')
  autoload(:Pathname, 'pathname')

  parameter('[SOURCE]', 'source name', { attribute_name: :param_source })
  option('--paragraphs', 'PARAGRAPHS',
         'paragraphs to generate',
         {
           default: 3,
           attribute_name: :param_paragraphs_count
         }, &:to_i)
  option('--heading', 'HEADING_LEVEL',
         'heading level',
         {
           default: 0,
           attribute_name: :param_heading_level
         }, &:to_i)
  option('--sentences', 'SENTENCES_COUNTS',
         [
           'sentences count(s) by paragraphs',
           'as range or integer',
           'randomly used when multiple definitions are given (comma separated)',
         ].join('-'),
         {
           default: '2..8,',
           attribute_name: :param_sentences_counts
         }, &:to_s)

  # @!attribute [r] param_heading_level
  #   @return [Integer]

  # @!attribute [r] param_paragraphs_count
  #   @return [Integer, nil]

  # @!attribute [r] param_sentences_counts
  #   @return [String]

  def variables
    {
      paragraphs: paragraphs,
      head: heading_command.then do |heading|
        heading ? -> { "#{heading}{#{titleizer.call}}" } : nil
      end,
    }
  end

  class << self
    protected

    def overridables
      {
        heading: :param_heading_level,
        paragraphs: :param_paragraphs_count,
        sentences: :param_sentences_counts,
      }.then { |override| super.merge(override) }
    end
  end

  protected

  # Provide a builder for title(s).
  #
  # @return [Proc]
  def titleizer
    lambda do |word_count: nil|
      word_count ||= [2, 3, 4].sample

      lovecraft.sentence(word_count: word_count, random_words_to_add: 0).gsub(/\.$/, '')
    end
  end

  # @return [Array<String>]
  def paragraphs
    sentences_count_maker = lambda do
      sentences_counts.sample.then { |v| v.is_a?(Range) ? rand(v) : v }
    end

    paragraphs_count.times.map do
      lovecraft.paragraph(sentence_count: sentences_count_maker.call, random_sentences_to_add: 0)
    end
  end

  # @return [Interger]
  def paragraphs_count
    param_paragraphs_count.to_i.abs
  end

  # @return [Integer, nil]
  def heading_level
    return nil if param_heading_level <= 0

    (param_heading_level - 1).then do |v|
      v >= 3 ? 3 : v
    end.to_i
  end

  # @return [Pathname, nil]
  def source
    super
  rescue StandardError
    nil
  end

  # Get counts used for paragraphs sentences.
  #
  # @return [Array<Range, Integer>]
  def sentences_counts
    param_sentences_counts
      .to_s
      .split(/\s*,\s*/)
      .keep_if { |v| v.match(/^[0-9]+(\.{2}[0-9]+)?$/) }
      .map { |v| v.split(/\.{2}/).map(&:to_i) }
      .map { |v| v.size == 2 ? v[0]..v[1] : v[0] }
  end

  # Produce a TeX command name from ``\section`` to ``\subsubsubsection``
  #
  # @return [String, nil]
  def heading_command
    # rubocop:disable Lint/RedundantSafeNavigation
    return nil unless heading_level&.is_a?(Integer)
    # rubocop:enable Lint/RedundantSafeNavigation

    "\\#{'sub' * heading_level.to_i}section"
  end

  def output_basepath
    source&.to_s || template_name
  end

  # @return [Class<Faker::Books::Lovecraft>]
  def lovecraft
    Faker::Books::Lovecraft
  end

  # @api private
  #
  # @return [Pathname]
  def pwd
    Pathname.new(Dir.pwd)
  end
end
