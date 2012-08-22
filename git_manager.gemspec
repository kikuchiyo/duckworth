Gem::Specification.new do |s|
  s.name        = 'git_manager'
  s.version     = '0.0.4'
  s.date        = '2012-08-21'
  s.summary     = "gem to manage git"
  s.description = "delete old git branches and blame pending specs\n" +
    "for e-mailing: requires config/email.yml file in root directory\n" +
    "for using build logs make sure you pass path to Git::Blames::Pending.new " + 
    "through :root parameter"
  s.authors     = ["kikuchiyo"]
  s.email       = 'kikuchiyo6@gmail.com'
  s.files       = ["lib/git_manager.rb", "lib/logs/2012-08-21_00-00-01", "config/email.yml"]
  s.test_files  = ["spec/git_manager_spec.rb"]
  s.homepage    =
    'http://rubygems.org/gems/git_manager'
end
