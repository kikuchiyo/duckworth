require 'rubygems'
require 'rspec'
require 'git_manager'

describe Git::Blames::Jenkins do
  it "initializes" do
    lambda{ 
      @task_assigner = Git::Blames::Jenkins.new(
        :build_directory => "#{Dir.pwd()}/lib"
        :jenkins_root => ''
        :job_name => ''
      )
    }.should_not raise_error

    it "builds correct job file path string" do
      @task_assigner.log_file.should == "" +
        "#{@jenkins_root}/jobs/#{@job_name}/builds/#{@job_number}/log"
    end 

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

  it "consolidates blames into structure for e-mailing each developer once" do
    expected_text =  "\n" +
      "  Spec:          spec/git_manager_spec.rb:11\n" +
      "    Collaborators: John Jimenez\n" +
      "    Title:           Fake test 2 spec/git_manager_spec.rb\n" +
      "    Details:           # Test 123\n\n\n" +
      "  Spec:          spec/git_manager_spec.rb:13\n" +
      "    Collaborators: John Jimenez\n" +
      "    Title:           Fake test 1 spec/git_manager_spec.rb\n" +
      "    Details:           # Test 123"

    @git_blames_pending.tasks_by_collaborator.should == {
      "John Jimenez" => expected_text,
      "Joe Schmoe" => '',
      "Jane Doe" => '',
    }
      # { "  Fake test 2 spec/git_manager_spec.rb"=>{
      #   :spec_file=>"spec/git_manager_spec.rb", 
      #   :details=>["    # Test 123"], 
      #   :contributors=>["John Jimenez"], 
      #   :name=>"  Fake test 2 spec/git_manager_spec.rb", 
      #   :line_number=>"11"
      # }, 
      # "  Fake test 1 spec/git_manager_spec.rb"=>{
      #   :spec_file=>"spec/git_manager_spec.rb", 
      #   :details=>["    # Test 123"], 
      #   :contributors=>["John Jimenez"], 
      #   :name=>"  Fake test 1 spec/git_manager_spec.rb", 
      #   :line_number=>"13"
      # }
  end
end 
