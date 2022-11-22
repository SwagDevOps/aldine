# frozen_string_literal: true

# vim: ai ts=2 sts=2 et sw=2 ft=ruby
# rubocop:disable all

# noinspection RubyLiteralArrayInspection
Gem::Specification.new do |s|
  s.name        = "aldine"
  s.version     = "0.0.5"
  s.date        = "2022-11-11"
  s.summary     = "Light utilities for LaTeX"
  s.description = "Light utilities for LaTeX (standalone document preparation system)"

  s.licenses    = ["LGPL-3.0"]
  s.authors     = ["Dimitri Arrigoni"]
  s.email       = "dimitri@arrigoni.me"
  s.homepage    = "https://github.com/SwagDevOps/aldine"

  s.required_ruby_version = ">= 2.7.0"
  s.require_paths = ["lib"]
  s.bindir        = "bin"
  s.executables   = [
    "aldine",
  ]
  s.files         = [
    ".env.sample",
    ".yardopts",
    "README.md",
    "bin/aldine",
    "lib/aldine.rb",
    "lib/aldine/bundleable.rb",
    "lib/aldine/cli.rb",
    "lib/aldine/cli/app.rb",
    "lib/aldine/cli/app/loader.rb",
    "lib/aldine/cli/app/loader/parser.rb",
    "lib/aldine/cli/base/base_command.rb",
    "lib/aldine/cli/base/erb_command.rb",
    "lib/aldine/cli/base/erb_command/output.rb",
    "lib/aldine/cli/base/erb_command/output_type.rb",
    "lib/aldine/cli/base/erb_command/rouge.rb",
    "lib/aldine/cli/base/erb_command/template.rb",
    "lib/aldine/cli/commands/chapters_command.rb",
    "lib/aldine/cli/commands/concerns/image_match.rb",
    "lib/aldine/cli/commands/concerns/input_yaml.rb",
    "lib/aldine/cli/commands/concerns/svg_convert.rb",
    "lib/aldine/cli/commands/hyperref_setup_command.rb",
    "lib/aldine/cli/commands/image_full_command.rb",
    "lib/aldine/cli/commands/miniature_command.rb",
    "lib/aldine/cli/commands/sample_command.rb",
    "lib/aldine/cli/commands/shared/files_matcher.rb",
    "lib/aldine/cli/commands/shared/svg_conv.rb",
    "lib/aldine/cli/commands/svg_conv_command.rb",
    "lib/aldine/concerns.rb",
    "lib/aldine/concerns/freezable.rb",
    "lib/aldine/concerns/freezer.rb",
    "lib/aldine/concerns/settings_aware.rb",
    "lib/aldine/dotenv_loader.rb",
    "lib/aldine/local.rb",
    "lib/aldine/local/config.rb",
    "lib/aldine/local/docker.rb",
    "lib/aldine/local/docker/command.rb",
    "lib/aldine/local/docker/env_file.rb",
    "lib/aldine/local/docker/rake_runner.rb",
    "lib/aldine/local/shell.rb",
    "lib/aldine/local/tasks.rb",
    "lib/aldine/local/tex.rb",
    "lib/aldine/remote.rb",
    "lib/aldine/remote/bundle_setup.rb",
    "lib/aldine/remote/config.rb",
    "lib/aldine/remote/inotify_wait.rb",
    "lib/aldine/remote/path.rb",
    "lib/aldine/remote/pdf_builder.rb",
    "lib/aldine/remote/synchro.rb",
    "lib/aldine/remote/tasks.rb",
    "lib/aldine/settings.rb",
    "lib/aldine/settings/parsed.rb",
    "lib/aldine/settings/parser.rb",
    "lib/aldine/shell.rb",
    "lib/aldine/shell/chalk.rb",
    "lib/aldine/shell/command.rb",
    "lib/aldine/shell/command_error.rb",
    "lib/aldine/shell/readline.rb",
    "lib/aldine/utils.rb",
    "lib/aldine/utils/bundle_config.rb",
    "lib/aldine/version.yml",
  ]

  s.add_runtime_dependency("clamp", ["~> 1.3"])
  s.add_runtime_dependency("dotenv", ["~> 2.8"])
  s.add_runtime_dependency("dotenv_validator", ["~> 1.2"])
  s.add_runtime_dependency("dry-inflector", ["~> 0.1"])
  s.add_runtime_dependency("faker", ["~> 2.21"])
  s.add_runtime_dependency("ice_nine", [">= 0"])
  s.add_runtime_dependency("kamaze-version", ["~> 1.0"])
  s.add_runtime_dependency("rouge", ["~> 3.29"])
  s.add_runtime_dependency("stibium-bundled", ["~> 0.0", ">= 0.0.4"])
  s.add_runtime_dependency("yard", ["~> 0.9"])
end

# Local Variables:
# mode: ruby
# End:
