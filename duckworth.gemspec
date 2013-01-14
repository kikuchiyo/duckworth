Gem::Specification.new do |s|
  s.name        = 'duckworth'
  s.version     = '0.0.1'
  s.date        = '2013-01-12'
  s.summary     = "QA Automation Engineer Assistant"
  s.description = "QA Automation Engineer Assistant, for Jenkins and Git."
  s.authors     = ["kikuchiyo"]
  s.email       = 'jimenez.john0@gmail.com'
  s.files       = [
    "lib/toolbag.rb",
    "lib/duckworth.rb",
    "config/email.yml"
  ]
  s.test_files  = [
    "spec/duckworth_spec.rb", 
    "spec/fixtures/jobs/assign_pending_tasks/builds/9/log",
    "spec/fixtures/jobs/assign_pending_tasks/nextBuildNumber",
    "spec/fixtures/jobs/assign_pending_tasks/workspace/spec/git_manager_spec.rb",
    "spec/fixtures/jobs/build_in_progress/builds/3/log",
    "spec/fixtures/jobs/build_in_progress/builds/4/log",
    "spec/fixtures/jobs/build_in_progress/nextBuildNumber",
    "spec/fixtures/jobs/build_in_progress/workspace",
    "spec/fixtures/jobs/build_missing_job_directory/builds/1",
    "spec/fixtures/jobs/malformed_job_directory"
  ]
  s.homepage    =
    'http://rubygems.org/gems/duckworth'
end


