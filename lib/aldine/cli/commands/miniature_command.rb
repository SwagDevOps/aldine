# frozen_string_literal: true

require_relative '../app'

# Produce miniature markup.
#
# @see http://tug.ctan.org/tex-archive/macros/latex/contrib/floatflt/floatflt.pdf
class Aldine::Cli::Commands::MiniatureCommand < Aldine::Cli::Base::ErbCommand
  include ::Aldine::Cli::Commands::Concerns::ImageMatch
  include ::Aldine::Cli::Commands::Concerns::SvgConvert

  class << self
    protected

    # @return [Hash{Symbol => Object}]
    def defaults
      {
        width: 2.0,
        margin: 0.1,
        position: self.positions.keys.fetch(0).to_s,
      }
    end

    # @return [Hash{Symbol => String}]
    def positions
      {
        right: 'r',
        left: 'l',
      }
    end
  end

  # @!attribute [rw] param_width
  #   @return [Float, nil]

  # @!attribute [rw] param_margin
  #   @return [Float, nil]

  # @!attribute [rw] param_position
  #   @return [String, nil]

  # set command options
  begin
    {
      width: 'image width',
      margin: 'image margin',
    }.each do |k, desc|
      { default: self.defaults[k], attribute_name: "param_#{k}" }.then do |opts|
        option("--#{k}", k.to_s.upcase, desc, opts) { |s| Float(s) }
      end
    end

    {
      default: self.defaults.fetch(:position),
      attribute_name: 'param_position',
    }.tap do |opts|
      option('--position', 'POSITION', 'miniature position', opts) do |s|
        self.class.__send__(:positions).fetch(s.to_sym, s).to_s
      end
    end
  end

  def output_basepath
    source.expand_path.to_path
  end

  # Translates source (filepath without extension) to the best matching file.
  #
  # @return [Pathname]
  def input_file
    image_match!(source)
  end

  # Get position (set from options, or default).
  #
  # @return [String]
  def position
    (self.param_position || self.defaults.fetch(:position)).then do |position|
      self.class.__send__(:positions).fetch(position.to_sym, position).to_s
    end
  end

  # Get image margin (as set from options, or default).
  #
  # @return [Float]
  def margin
    # noinspection RubyMismatchedReturnType
    self.param_margin || defaults[:margin]
  end

  # Get image width (as set from options, or default).
  #
  # @return [Float]
  def width
    # noinspection RubyMismatchedReturnType
    self.param_width || defaults[:width]
  end

  protected

  # @return [Hash{Symbol => Object}]
  def defaults
    self.class.__send__(:defaults)
  end

  # Get dimensions, used in template.
  #
  # @return [Array<Float>]
  def dimensions
    [width + margin, width].freeze
  end

  def variables_builder
    lambda do
      {
        input_file: self.input_file,
        image_file: input_file.extname == '.svg' ? svg_convert(input_file) : input_file,
        dimensions: self.dimensions,
        position: self.position,
      }
    end
  end
end
