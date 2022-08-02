# frozen_string_literal: true

require_relative '../app'

# Process chapters/sections.
#
# Sample of use:
#
# ```
# aldine chapters .
# aldine chapters chapters
# aldine chapters chapters.yml
# ````
class Aldine::Cli::Commands::ChaptersCommand < Aldine::Cli::Base::ErbCommand
  include ::Aldine::Cli::Commands::Concerns::InputYaml

  def output_basepath
    input_file.expand_path.dirname.join(input_file.basename('.*')).to_path
  end

  def variables
    {
      files: files,
      chapters: files.map { |str| str.to_s.gsub(/\.tex$/, '') },
    }
  end

  # File used to process chapters.
  #
  # @return [Pathname]
  def input_file
    Pathname.new("#{source.to_s.gsub(/\.yml$/, '')}.yml").freeze
  end

  protected

  # Where TeX files are located.
  #
  # @return [Pathname]
  def texfiles_basedir
    input_file.dirname.join(options.fetch(:basedir))
  end

  # @return [Array<Pathname>]
  def files
    input_yaml.map { |fp| texfiles_basedir.join("#{fp}.tex").freeze }
  end

  # Get some options.
  #
  # This code is legacy amd SHOULD BE removed in the future.
  #
  # @api private
  #
  # @return {Hash{Symbol => Object}}
  def options
    { basedir: input_file.basename('.*').to_s }
  end
end
