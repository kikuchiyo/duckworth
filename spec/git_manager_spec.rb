require 'rubygems'
require 'rspec'
require 'git_manager'

describe Git do
  describe Git::Managed::Branch do
    before :each do
      @git_manager = Git::Managed::Branch.new
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
      Git::Managed::Branch.any_instance.stub(:delete_branch).and_return( true )
  
      @git_manager.branches_to_delete = ['some_fake_branch']
      @git_manager.delete_branches.should_not == false
    end
  end 
  
  describe Git::Blames::Pending do
    before :each do
      Git::Blames::Pending.any_instance.stub(:rspec_results){'mr huxtable'}
      @test_01 = '  Fake test 1 spec/git_manager_spec.rb'
      @test_02 = '  Fake test 2 spec/git_manager_spec.rb'
      @git_blames_pending = Git::Blames::Pending.new(:root => './lib/logs')
      @expected_tasks = {
        @test_01  => {
          :spec_file  => 'spec/git_manager_spec.rb',
          :details=>["    # Test 123"],
          :line_number => '13',
          :contributors => ['John Jimenez'],
          :name => "  Fake test 1 spec/git_manager_spec.rb"
        },
        @test_02 => {
          :spec_file  => 'spec/git_manager_spec.rb',
          :details=>["    # Test 123"],
          :line_number => '11',
          :contributors => ['John Jimenez'],
          :name => "  Fake test 2 spec/git_manager_spec.rb"
        }
      }
    end
     
    it "collects pending specs as expected" do
      @git_blames_pending.tasks[@test_01][:spec_file].should == @expected_tasks[@test_01][:spec_file]
      @git_blames_pending.tasks[@test_02][:spec_file].should == @expected_tasks[@test_02][:spec_file]
    end 

    it "collects pending spec line number as expected" do
      @git_blames_pending.tasks[@test_01][:line_number].should == @expected_tasks[@test_01][:line_number]
      @git_blames_pending.tasks[@test_02][:line_number].should == @expected_tasks[@test_02][:line_number]
    end 

    it "collects pending spec name as expected" do
      @git_blames_pending.tasks[@test_01][:spec_name].should == @expected_tasks[@test_01][:spec_name]
      @git_blames_pending.tasks[@test_02][:spec_name].should == @expected_tasks[@test_02][:spec_name]
    end 

    it "collects pending spec contributors as expected" do
      @git_blames_pending.tasks[@test_01][:contributors].should == @expected_tasks[@test_01][:contributors]
      @git_blames_pending.tasks[@test_02][:contributors].should == @expected_tasks[@test_02][:contributors]
    end 

    it "collects pending spec details as expected" do
      @git_blames_pending.tasks[@test_01][:details].should == @expected_tasks[@test_01][:details]
      @git_blames_pending.tasks[@test_02][:details].should == @expected_tasks[@test_02][:details]
    end 
  end 
end 
