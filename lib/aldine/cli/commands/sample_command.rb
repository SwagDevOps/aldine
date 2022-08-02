# frozen_string_literal: true

require_relative '../app'

# A sample command.
#
# This is a simple sample command.
# Illustrates basic features. Produces random quotes in a HP Lovecraft's style.
class Aldine::Cli::Commands::SampleCommand < Aldine::Cli::Base::ErbCommand
  autoload(:Faker, 'faker')
  autoload(:Digest, 'digest')
  autoload(:Pathname, 'pathname')

  def variables
    {
      lovecraft: lovecraft,
    }
  end

  # @return [Pathname, nil]
  def source
    lambda do
      super
    rescue StandardError
      template_name
    end.call.then { |v| Pathname.new(v.to_s) }
  end

  class << self
    # @todo add a better override for already defined pararemters
    def parameters
      super.tap do |parameters|
        if parameters[0].name == 'SOURCE'
          parameters[0] = Clamp::Parameter::Definition.new('[SOURCE]', 'source', { attribute_name: :param_source })
        end
      end
    end
  end

  protected

  def output_basepath
    [template_name, Digest::SHA1.hexdigest(source.to_s)].then do |parts|
      pwd.join(parts.join('.')).to_path
    end
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
