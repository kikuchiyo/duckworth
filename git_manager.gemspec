Gem::Specification.new do |s|
  s.name        = 'git_manager'
  s.version     = '0.1.2'
  s.date        = '2012-10-31'
  s.summary     = "qa automation engineer assistant"
  s.description = "A QA Automation Enineer's Assistant, utilizing Jenkins and Git."
  s.authors     = ["kikuchiyo"]
  s.email       = 'jimenez.john0@gmail.com'
  s.files       = [
    "lib/logs/2012-08-21_00-00-02/log", 
    "lib/blames/pending.rb",
    "lib/managed/branch.rb",
    "lib/git_manager.rb",
    "lib/git_manager.rb", 
    "config/email.yml",
    "lib/managed.rb",
    "lib/blames.rb",
    "lib/emails.rb",
    "lib/git.rb"
  ]
  s.test_files  = ["spec/git_manager_spec.rb"]
  s.homepage    =
    'http://rubygems.org/gems/git_manager'
end
