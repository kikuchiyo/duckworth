class Git::Blames::Pending 
  attr_accessor :tasks, :rspec_results

  include Git::Blames

  def initialize options = nil
    if options.nil? || options[:root].nil? && !options[:rspec] && !options[:log]
      @root = "#{File.dirname(__FILE__)}/logs"
    elsif options[:log]
      find_pending_specs_by_logfile_name( options[:log] )
    elsif options[:rspec]
      find_pending_specs_by_rspec_results( rspec_results )
    else
      @root = options[:root]
      find_pending_specs_by_logfile_name( "#{@root}/#{find_last_logfile_name}" )
    end
    find_contributors
  end

  def rspec_results
    results =  `rspec spec`
    results
  end

  def find_contributors
    # @tasks = Git::Blames::Pending.new.tasks
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

  def found_pending_marker line
    line.match( /^[\s\t]*Pending:/ )
  end

  def found_new_spec_marker line, status
    ( status == 'start' || status == 'updating spec data' ) && !line.match( /^[\s\t]*#/ )
  end

  def found_spec_details_marker line, status
    ( status == 'found new pending spec' || status == 'updating spec data' ) && line.match( /^[\s\t]*\#/ )
  end

  def find_last_logfile_name
    begin
      files = Dir.new @root
    rescue => e 
      begin
      Dir.mkdir @root
      files = Dir.new @root
      rescue
        puts e
      end
    end
    file_name = files.to_a.select { |log| log.match /\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}/ }.sort.last
    "#{file_name}/log"
  end

  def find_pending_specs_by_rspec_results spec_output
    status = ''
    @tasks = {}
    task = {}

    spec_output.each do |line|
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

  def find_pending_specs_by_logfile_name logfile_name
    logfile = File.new( logfile_name )
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
