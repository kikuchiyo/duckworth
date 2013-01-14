class Duckworth
  def initialize options
    @jenkins_root = options[:jenkins_root]
    @job_name = options[:job_name]
    @log_dir = log_dir_from_builds_path( builds_path )
    @last_log = "#{@log_dir}/log"
  end

  def workspace
    "#{@jenkins_root}/workspace"
  end

  def builds_path
    "#{@jenkins_root}/jobs/#{@job_name}/builds"
  end

  def log_dir_from_builds_path( builds_path )
    "#{ builds_path }/#{ last_build_number( builds_path ) }"
  end

  def last_build_number( builds_path )
    File.open(
      "#{builds_path}/nextBuildNumber", 'r'
    ).readlines.each { |line| line }.first.to_i - 1
  end

  def assign_pending_tasks
    Git::Blames::Pending.new(
      :log_file_name => @last_log, :workspace => @workspace
    ).blame( :email => true )
  end
end

class Git::Blames::Pending 
  attr_accessor :tasks, :rspec_results

  include Git::Blames

  def initialize options = nil
    @log_file_name = optins[:log_file_name]    
    find_pending_specs
    find_contributors
  end

  def finder
    @tasks.each_pair do |key, attributes|
      contributors = []
      `git blame "#{attributes[:spec_file]}"`.each do |blame|
        contributor = blame.split(")")[0].split("(")[1]
        contributor = contributor.split(/\s+\d/)[0]
        contributors.push( contributor )
      end
      @tasks[key][:contributors] = contributors.uniq
      @tasks[key][:contributors].reject!{ |contributor| contributor == 'Not Committed Yet'}
    end
    @tasks
  end

  def find_contributors
    Dir.chdir( @workspace ) { 
      puts Dir.pwd()
      finder 
    }
    finder
    @tasks
  end

  def found_pending_marker line
    line.match( /^[\s\t]*Pending:/ )
  end

  def found_new_spec_marker line, status
    ( status == 'start' || status == 'updating spec data' ) && !line.match( /^[\s\t]*#/ )
  end

  def found_spec_details_marker line, status
    ( status == 'found new pending spec' || status == 'updating spec data' ) && line.match( /^[\s\t]*\#/ )
  end

  def find_pending_specs
    logfile = File.new( @log_file_name )
    status = ''
    @tasks = {}
    task = {}

    logfile.readlines.each do |line|

      if found_pending_marker line
        status = 'start'
        
      elsif found_new_spec_marker line, status
        status = 'found new pending spec'  
        task = {}
        task[:name] = line.chomp
        task[:details] = []

      elsif found_spec_details_marker line, status
        status = 'updating spec data'
        if line.match /(spec.*)[:](\d+)/
          task[:spec_file] = $1
          task[:line_number] = $2
        else
          task[:details].push line.chomp
        end
        @tasks[task[:name]] = task
      end
    end
  end

  def tasks_by_collaborator
    load_configuration
    consolidated_emails = {}
    @email_mappings.each_key do |contributor|
      consolidated_emails[contributor] = []
      @tasks.each do |object|
        key = object[0]
        values = object[1]
        if values[:contributors].include?( contributor )
          message = "\n" +
            "  Spec:          #{values[:spec_file]}:#{values[:line_number]}\n" +
            "    Collaborators: #{values[:contributors].join(',')}\n" +
            "    Title:         #{values[:name]}\n" +
            "    Details:       #{values[:details].join('\n')}"
          consolidated_emails[contributor].push( message )
        end
      end
      consolidated_emails[contributor] = consolidated_emails[contributor].join(
        "\n\n"
      )
    end
    consolidated_emails
  end
end
