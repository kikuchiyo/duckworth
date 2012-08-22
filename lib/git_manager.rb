require 'rubygems'

# usage Git::Blames::Pending.new.blame
# usage Git::Managed::Branch.new.delete_branches

module Git
  module Managed
    class Branch
    end
  end
  module Blames
    def blame
      self.tasks.each_pair do |key, attributes|
        puts "\nPending Spec Information:"
        puts "  Description: #{key}"
        puts "  Contributors: #{attributes[:contributors].join(', ')}"
        puts "  File: #{attributes[:spec_file]}"
        puts "  Line: #{attributes[:line_number]}\n"
      end
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
  attr_accessor :tasks
  include Git::Blames
  def initialize
    @root = "#{File.dirname(__FILE__)}/logs"
    find_pending_specs_by_logfile_name( "#{@root}/#{find_last_logfile_name}" )
    find_contributors
  end

  def find_contributors
    # @tasks = Git::Blames::Pending.new.tasks
    contributors = []
    @tasks.each_pair do |key, attributes|
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
    files.to_a.select { |log| log.match /\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}/ }.sort.last
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

