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

module Git
  module Emails
    def load_configuration
      config = YAML::load_file('./config/email.yml')
      @email_from = config['authentication']['from']
      @email_password = config['authentication']['password']
      @email_mappings = config['users']
      puts "email_mappings = #{@email_mappings.inspect}"
    end
  
    def send_gmail options
      load_configuration
      recipients = options[:recipients]
      puts "recipients = #{recipients.inspect}"
      msg = "Subject: #{options[:subject]}\n\n#{options[:message]}"
      smtp = Net::SMTP.new 'smtp.gmail.com', 587
      smtp.enable_starttls
      smtp.start( '', @email_from, @email_password, :login ) do
        smtp.send_message( msg, @email_from, recipients.map{ |recipient| @email_mappings["#{recipient.gsub(' ', '_') }" ] } )
      end
    end
  end

  module Managed
    class Branch
    end
  end

  module Blames
    include Git::Emails
    def blame(options = nil)
      self.tasks.each_pair do |key, attributes|
        if options.nil? || !options[:email]
          stdout key, attributes
        else
          send_gmail :recipients => attributes[:contributors],
            :subject => "Please collaborate to fix spec: " +
              "#{attributes[:spec_file]} : " +
              "#{attributes[:line_number]}",
            :message => "Spec Details:\n  " +
              "Details\n  #{attributes[:details].join('\n')}\n" +
              "Collaborators:\n  #{attributes[:contributors].join(', ')}\n"
        end
      end
    end
    def stdout key, attributes
      puts "\nPending Spec Information:"
      puts "  Description: #{key}"
      puts "  Contributors: #{attributes[:contributors].join(', ')}"
      puts "  File: #{attributes[:spec_file]}"
      puts "  Line: #{attributes[:line_number]}\n"
    end
    class Pending
    end
    class Blame
    end
  end
end

class Git::Managed::Branch
  attr_accessor :branches, :current_branch, :branches_to_delete
  def initialize
    @branches = `git branch`.split /\n/
    partition_branches
  end
  def partition_branches
    @current_branch = @branches.select {|branch| branch.match /^\*/}.first
    @branches_to_delete = @branches.select {|branch| branch != @current_branch }
    @current_branch.chomp!
    @current_branch.gsub! /\s|\*/, ''
  end

  def delete_branches
    return false if @branches_to_delete.length == 0
    @branches_to_delete.each do |branch|
      delete_branch( branch.gsub /\s/, '' )
    end
  end

  def delete_branch branch
    `git branch -D #{branch}`
  end

end

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
end
