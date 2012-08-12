require 'rubygems'
require 'rspec'
require 'git_manager'

describe Git::Manager do
  before :each do
    @git_manager = Git::Manager.new
  end
  it "has branches" do
    @git_manager.branches.should_not be_nil
  end    
  it "has branches array" do
    @git_manager.branches.class.should == Array
  end    
  it "knows about current branch" do
    @git_manager.current_branch.should == 'master'
  end 
  it "knows about branches to delete" do
    @git_manager.branches_to_delete.should_not be_nil
  end 
  it "aborts if branches to delete is empty" do
    @git_manager.branches_to_delete = []
    @git_manager.delete_branches.should == false
  end
  it "deltes branches to delete if NOT empty" do
    @fake_branch_name = 'some_fake_branch'
    Git::Manager.any_instance.stub(:delete_branch).and_return( true )

    @git_manager.branches_to_delete = ['some_fake_branch']
    @git_manager.delete_branches.should_not == false
  end
end 


