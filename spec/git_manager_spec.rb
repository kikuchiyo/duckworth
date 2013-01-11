require 'rubygems'
require 'rspec'
require 'git_manager'

describe Git do
  it "has a managed class" do
    lambda{ Git::Managed }.should_not raise_error
  end  

  it "has a blames class" do
    lambda{ Git::Blames }.should_not raise_error
  end  

  it "has a pending class" do
    lambda{ Git::Blames::Pending }.should_not raise_error
  end  
end 
