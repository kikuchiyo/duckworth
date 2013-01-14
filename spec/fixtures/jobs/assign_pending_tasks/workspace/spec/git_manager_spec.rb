require 'rubygems'
require 'rspec'
require 'lib/duckworth'

describe Duckworth do
  describe "Preparation" do
    before :each do
      @errors = {
        :no_jenkins_root => "" +
          "Duckworth cannot work without a :jenkins_root. " +
          "Create new instances like Duckworth.new( " +
          ":jenkins_root => <directory_containing_jobs_directory>, " +
          ":job_name => <name_of_job_duckworth_will_work_on>)",

        :no_job_name => "" +
          "Duckworth cannot work without a :job_name. " +
          "Create new instances like Duckworth.new( " +
          ":jenkins_root => <directory_containing_jobs_directory>, " +
          ":job_name => <name_of_job_duckworth_will_work_on>)",

        :dne_jenkins_root => "Duckworth cannot find path for :jenkins_root.",
        :dne_job_name => "Duckworth cannot find path for :job_name.",
        :no_build_number => "Duckworth cannot find nextBuildNumber file.",
        :dne_build_number => "Duckworth cannot find log file for nextBuildNumber." 
      }
    end
     
    it "refuses to work without proper instructions" do
      lambda{ Duckworth.new }.should raise_error @errors[:no_jenkins_root]
      lambda{ 
        Duckworth.new( :jenkins_root => 'asdf') 
      }.should raise_error @errors[:dne_jenkins_root]

      lambda{ 
        Duckworth.new(:jenkins_root => '/') 
      }.should raise_error @errors[:no_job_name]

    end   

    it "refuses to work on wild goose chases" do
      lambda{ 
        Duckworth.new(:jenkins_root => '/', :job_name => 'asdf') 
      }.should raise_error @errors[:dne_job_name]

      lambda{ 
        Duckworth.new(
          :jenkins_root => './spec/fixtures', 
          :job_name => 'malformed_job_directory'
        ) 
      }.should raise_error @errors[:no_build_number]

      lambda{ 
        Duckworth.new(
          :jenkins_root => './spec/fixtures', 
          :job_name => 'build_missing_job_directory'
        ) 
      }.should raise_error @errors[:dne_build_number]

    end 
    
    it "knows when build is in progress, and will revert previous build" do
      Duckworth.new(
        :jenkins_root => './spec/fixtures', 
        :job_name => 'build_in_progress'
      ).build_number.should == 3
    end 

  end 

  it "prepares for work when initialized with proper instructions" do
    lambda{
      @duckworth = Duckworth.new(
        :jenkins_root => './spec/fixtures',
        :job_name => 'assign_pending_tasks'
      )
    }.should_not raise_error

    @duckworth.class.should == Duckworth

    @duckworth.workspace.should == 
      './spec/fixtures/jobs/assign_pending_tasks/workspace'

    @duckworth.log.should == 
      './spec/fixtures/jobs/assign_pending_tasks/builds/9/log'

    @duckworth.build_number.should == 9
  end   
end 

describe Duckworth do
  before :each do
    @test_01 = '  Fake test 1 spec/git_manager_spec.rb'
    @test_02 = '  Fake test 2 spec/git_manager_spec.rb'

    @duckworth = Duckworth.new(
      :jenkins_root => './spec/fixtures',
      :job_name => 'assign_pending_tasks'
    ).blame( :email => false )

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
    @duckworth.tasks[@test_01][:spec_file].should == @expected_tasks[@test_01][:spec_file]
    @duckworth.tasks[@test_02][:spec_file].should == @expected_tasks[@test_02][:spec_file]
  end 

  it "collects pending spec line number as expected" do
    @duckworth.tasks[@test_01][:line_number].should == @expected_tasks[@test_01][:line_number]
    @duckworth.tasks[@test_02][:line_number].should == @expected_tasks[@test_02][:line_number]
  end 

  it "collects pending spec name as expected" do
    @duckworth.tasks[@test_01][:spec_name].should == @expected_tasks[@test_01][:spec_name]
    @duckworth.tasks[@test_02][:spec_name].should == @expected_tasks[@test_02][:spec_name]
  end 

  it "collects pending spec contributors as expected" do
    @duckworth.tasks[@test_01][:contributors].should == @expected_tasks[@test_01][:contributors]
    @duckworth.tasks[@test_02][:contributors].should == @expected_tasks[@test_02][:contributors]
  end 

  it "collects pending spec details as expected" do
    @duckworth.tasks[@test_01][:details].should == @expected_tasks[@test_01][:details]
    @duckworth.tasks[@test_02][:details].should == @expected_tasks[@test_02][:details]
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

    @duckworth.tasks_by_contributor.should == {
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
