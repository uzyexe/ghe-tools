require 'rubocop/rake_task'

task :default => [':style']

desc 'Run all tests on CircleCI'
task :circleci => [':style']

desc 'Run all style checks'
task :style => ['style:ruby']

# Style tests. Rubocop
namespace :style do
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:ruby) do |t|
    t.patterns = [
      'Rakefile',
      '*.rb'
    ]
  end
end
