# frozen_string_literal: true

if project.path('spec').directory?
  task :spec do |_, args|
    # @type [Rake::Task] task
    Rake::Task[:test].then { |task| task.invoke(*args.to_a) }
  end
end
