# frozen_string_literal: true

require_relative '../../app'

# Provide TAML read based on ``input_file`` method.
module Aldine::Cli::Commands::Concerns::InputYaml
  autoload(:YAML, 'yaml')

  protected

  # Load YAML file.
  #
  # @return [Array, Hash]
  def input_yaml
    YAML.safe_load(input_file.read)
  end
end
