# frozen_string_literal: true

require "bundler"
Bundler.setup

require "rspec/core/rake_task"

desc "Run end to end tests against local environment"
RSpec::Core::RakeTask.new(:end_to_end) do |task|
  ENV["SKIP_AUTH"] ||= "1"
  ENV["SKIP_S3"] ||= "1"
  ENV["SKIP_FILE_UPLOAD"] ||= "1"

  ENV["FORMS_ADMIN_URL"] ||= "http://localhost:3000/"
  ENV["FORMS_RUNNER_URL"] ||= "http://localhost:3001/"
  ENV["PRODUCT_PAGES_URL"] ||= "http://localhost:3002/"

  ENV["SETTINGS__SUBMISSION_STATUS_API__SECRET"] ||= "test_token"

  task.pattern = %(spec/end_to_end)
  task.verbose = false
end

task default: %i[end_to_end]
