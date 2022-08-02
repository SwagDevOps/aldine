# frozen_string_literal: true

require_relative '../app'

# Produce all full/big image markup.
class Aldine::Cli::Commands::ImageFullCommand < Aldine::Cli::Base::ErbCommand
  include ::Aldine::Cli::Commands::Concerns::ImageMatch
  include ::Aldine::Cli::Commands::Concerns::SvgConvert

  def output_basepath
    source.expand_path.to_path
  end

  # Translates source (filepath without extension) to the best matching file.
  #
  # @return [Pathname]
  def input_file
    image_match!(source)
  end

  protected

  def variables_builder
    lambda do
      {
        input_file: self.input_file,
        image_file: input_file.extname == '.svg' ? svg_convert(input_file) : input_file,
      }
    end
  end
end
