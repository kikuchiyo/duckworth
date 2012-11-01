# example usage 
#   Git::Blames::Pending.new(
#     :log => <explicit log file to test against>
#     :root => <root folder where build logs are located>
#     :rspec => boolean specifying whether or 
#       not you want to run rspec now to get pending specs
#   ).blame( :email => true )
#   for emailing create a config/email.yml file as specified
#   in this gems own config/email.yml file
# example usage 
#   Git::Managed::Branch.new.delete_branches

require 'rubygems'
require 'net/smtp'
require 'yaml'
require "#{ File.dirname(  __FILE__ ) }/git"
require "#{ File.dirname(  __FILE__ ) }/managed"
require "#{ File.dirname(  __FILE__ ) }/managed/branch"
require "#{ File.dirname(  __FILE__ ) }/emails"
require "#{ File.dirname(  __FILE__ ) }/blames"
require "#{ File.dirname(  __FILE__ ) }/blames/pending"

Git::Blames::Pending.new( :root => './lib/logs/' ).blame( :email => true )
