require 'rubygems'
module Git
  class Manager
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
end

