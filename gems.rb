# frozen_string_literal: true

# ```sh
# bundle config set --local clean 'true'
# bundle config set --local path 'vendor/bundle'
# bundle install --standalone
# ```
source 'https://rubygems.org'

def github(repo, options = {}, &block)
  block ||= -> { gem(*[File.basename(repo)].concat([{ github: repo }.merge(options)])) }

  # noinspection RubySuperCallWithoutSuperclassInspection
  super(repo, options, &block)
end

group :default do
  gem 'clamp', '~> 1.3'
  gem 'dotenv', '~> 2.8'
  gem 'faker', '~> 2.21'
  gem 'kamaze-version', '~> 1.0'
  gem 'rouge', '~> 3.29'
  gem 'stibium-bundled', '~> 0.0', '>= 0.0.4'
  gem 'yard', '~> 0.9'
end

group :development do
  github 'SwagDevOps/kamaze-project', { branch: 'develop' }
  gem 'listen', '~> 3.1'
  gem 'rake', '~> 13.0'
  gem 'rubocop', '~> 1.3'
  gem 'rugged', '~> 1.0'
  gem 'sys-proc', '~> 1.1'
  # repl ---------------------------------
  gem 'interesting_methods', '~> 0.1'
  gem 'pry', '~> 0.12'
  gem 'rb-readline', '~> 0.5'
end

group :doc do
  gem 'github-markup', '~> 3.0'
  gem 'redcarpet', '~> 3.5'
  gem 'yard-coderay', '~> 0.1'
end
