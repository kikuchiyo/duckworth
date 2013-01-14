require 'net/smtp'
require 'yaml'
require 'lib/toolbag'

class Duckworth
  include Toolbag::Parses
  include Toolbag::Searches
  include Toolbag::Organizes
  include Toolbag::Writes
  include Toolbag::Communicates

  attr_accessor :build_number, :tasks

  def initialize( guidlines = {} )
    # call prepare
    prepare( guidlines )
    find and organize
  end

  def prepare guidlines
    verify_provided_guidlines( guidlines )
  end

  def find
    # Find the pending specs
    find_pending_specs
  end

  def organize
    # Organize the pending specs
    find_contributors
  end

  def mail
    # Mail the pending specs
  end

  # protected

  def workspace
    "#{@job_root}/workspace"
  end

  def log
    "#{@builds}/#{@build_number}/log"
  end

  private

    def verify_provided_guidlines guidlines
      root = guidlines[:jenkins_root]
      name = guidlines[:job_name]
      @builds = "#{root}/jobs/#{name}/builds"
      @job_root = "#{root}/jobs/#{name}"

      raise errors( :no_jenkins_root ) if root.nil?
      unless File.exist?(root) and File.directory?( root )
        raise errors( :dne_jenkins_root ) 
      end

      raise errors( :no_job_name ) if name.nil?
      unless directory? "#{root}/jobs/#{name}"
        raise errors( :dne_job_name ) 
      end
     
      next_build = "#{root}/jobs/#{name}/nextBuildNumber"

      unless file? next_build
        raise errors( :no_build_number ) 
      end

      unless directory? "#{@builds}/#{last_build_number( next_build )}"
        raise errors(:dne_build_number)
      end
    end

    def errors why_i_refuse_to_work
      general_help = "" +
        "Create new instances like Duckworth.new( " +
        ":jenkins_root => <directory_containing_jobs_directory>, " +
        ":job_name => <name_of_job_duckworth_will_work_on>)"

      { :no_jenkins_root => "Duckworth cannot work without a :jenkins_root. ",
        :no_job_name => "Duckworth cannot work without a :job_name. ",
        :dne_jenkins_root => "Duckworth cannot find path for :jenkins_root.",
        :dne_job_name => "Duckworth cannot find path for :job_name.",
        :no_build_number => "Duckworth cannot find nextBuildNumber file.",
        :dne_build_number => "Duckworth cannot find log file for nextBuildNumber." 
      }[why_i_refuse_to_work] + 
        ( why_i_refuse_to_work.to_s.match( /dne|build_number/ ) ? '' : general_help )
    end

    def file? file
      File.exist?( file ) and File.file?( file )
    end

    def directory? directory
      File.exist?( directory ) and File.directory?( directory )
    end

    def last_build_number( next_build_number_file )
      build_number = File.open(
        next_build_number_file, 'r'
      ).readlines.each { |line| line }.first.to_i - 1

      unless File.exist?( "#{@builds}/#{build_number}/log" )
        raise errors(:dne_build_number)
      end

      job_in_progress = File.open(
        "#{@builds}/#{build_number}/log", 'r'
      ).readlines.select { |line| line.match /Finished: (SUCCESS|FAILURE)/ }.empty?

      build_number -= 1 if job_in_progress
      raise 'First Build Still in progress' if build_number == 0
      @build_number = build_number
      build_number
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
      logfile = File.new( log )
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

    # def finder
    #   @tasks.each_pair do |key, attributes|
    #     contributors = []
    #     `git blame "#{attributes[:spec_file]}"`.each do |blame|
    #       contributor = blame.split(")")[0].split("(")[1]
    #       contributor = contributor.split(/\s+\d/)[0]
    #       contributors.push( contributor )
    #     end
    #     @tasks[key][:contributors] = contributors.uniq
    #     @tasks[key][:contributors].reject!{ |contributor| contributor == 'Not Committed Yet'}
    #   end
    #   @tasks
    # end

    # def find_contributors
    #   Dir.chdir( workspace ) { 
    #     puts Dir.pwd()
    #     finder 
    #   }
    #   finder
    #   @tasks
    # end

    # def tasks_by_collaborator
    #   load_configuration
    #   consolidated_emails = {}
    #   @email_mappings.each_key do |contributor|
    #     consolidated_emails[contributor] = []
    #     @tasks.each do |object|
    #       key = object[0]
    #       values = object[1]
    #       if values[:contributors].include?( contributor )
    #         message = "\n" +
    #           "  Spec:          #{values[:spec_file]}:#{values[:line_number]}\n" +
    #           "    Collaborators: #{values[:contributors].join(',')}\n" +
    #           "    Title:         #{values[:name]}\n" +
    #           "    Details:       #{values[:details].join('\n')}"
    #         consolidated_emails[contributor].push( message )
    #       end
    #     end
    #     consolidated_emails[contributor] = consolidated_emails[contributor].join(
    #       "\n\n"
    #     )
    #   end
    #   consolidated_emails
    # end

    # def blame(options = nil)
    #   if !options[:spam]
    #     self.tasks_by_collaborator.each_pair do |recipient, message|
    #       if message == ''
    #         subject = 'Congratulations, you have no pending specs! :)'
    #         messy   = 'Woot!'
    #       else
    #         subject = "Please collaborate to fix consolidated list of specs: "
    #         messy   = message
    #       end

    #       send_gmail( 
    #         :recipients => [recipient],
    #         :subject => subject,
    #         :message => messy
    #       )
    #     end
    #   else
    #     self.tasks.each_pair do |key, attributes|
    #       if options.nil? || !options[:email]
    #         stdout key, attributes
    #       else
    #         send_gmail :recipients => attributes[:contributors],
    #           :subject => "Please collaborate to fix spec: " +
    #             "#{attributes[:spec_file]} : " +
    #             "#{attributes[:line_number]}",
    #           :message => "Spec Details:\n  " +
    #             "Details\n  #{attributes[:details].join('\n')}\n" +
    #             "Collaborators:\n  #{attributes[:contributors].join(', ')}\n"
    #       end
    #     end
    #   end
    # end

    # def stdout key, attributes
    #   puts "\nPending Spec Information:"
    #   puts "  Description: #{key}"
    #   puts "  Contributors: #{attributes[:contributors].join(', ')}"
    #   puts "  File: #{attributes[:spec_file]}"
    #   puts "  Line: #{attributes[:line_number]}\n"
    # end

    # def load_configuration
    #   config = YAML::load_file( './config/email.yml' )
    #   @email_from = config['authentication']['from']
    #   @email_password = config['authentication']['password']
    #   @email_mappings = config['users']
    # end

    # def send_gmail options
    #   load_configuration
    #   recipients = options[:recipients]
    #   msg = "Subject: #{options[:subject]}\n\n#{options[:message]}"
    #   smtp = Net::SMTP.new 'smtp.gmail.com', 587
    #   smtp.enable_starttls
    #   puts "Sending e-mail to #{recipients.join(',')}"
    #   smtp.start( '', @email_from, @email_password, :login ) do
    #     smtp.send_message( msg, @email_from, recipients.map{ |recipient| 
    #         # @email_mappings["#{recipient.gsub(' ', '_') }" ] 
    #         @email_mappings[ recipient ] 
    #     })
    #   end
    # end
end
