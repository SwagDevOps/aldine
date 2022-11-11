# frozen_string_literal: true

require 'kamaze/project'

# noinspection RubyLiteralArrayInspection
[
  'cs:correct',
  'cs:control',
  'cs:pre-commit',
  'doc',
  'doc:watch',
  'gem:gemspec',
  'misc:gitignore',
  'shell',
  'sources:license',
  'version:edit',
].then do |tasks|
  Kamaze.project do |project|
    project.subject = Aldine
    project.name = 'aldine'
    project.tasks = tasks
  end.load!
end

# default task --------------------------------------------------------
task default: ['gem:gemspec']

# tasks ---------------------------------------------------------------
Dir.glob("#{__dir__}/tasks/**/*.rb").sort.each { |fp| require(fp) }
