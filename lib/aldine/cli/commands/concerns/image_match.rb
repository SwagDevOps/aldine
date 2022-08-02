# frozen_string_literal: true

require_relative '../../app'

# Provide methods to match image files with a filepath without extension (``source``).
module Aldine::Cli::Commands::Concerns::ImageMatch
  protected

  # Get best match for given filepath without extension.
  #
  # @note Fails on empty result.
  #
  # @param [Pathname] source
  #
  # @return [Pathname]
  def image_match!(source)
    image_match(source).tap do |match|
      if match.nil?
        raise "Can not match image file with as #{source.to_path.inspect}"
      end
    end
  end

  # Get best match for given filepath without extension.
  #
  # @param [Pathname] source
  #
  # @return [Pathname, nil]
  def image_match(source)
    images_matcher.call(source).values.first
  end

  # Get instance of images matcher.
  #
  # @return [Aldine::Cli::Commands::Shared::FilesMatcher]
  def images_matcher
    ::Aldine::Cli::Commands::Shared::FilesMatcher.new(images_extensions)
  end

  # @return [Array<Symbol>]
  def images_extensions
    [:pdf, :svg, :png, :jpg, :jpeg].freeze
  end
end
