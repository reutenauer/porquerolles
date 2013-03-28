#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'

# Sudoku command-line parsing.

# TODO tree option, verbose option.
# I’ll play with optparse later.

class SudokuMain
  def self.run(args)
    params = { }

    # TODO Play with optparse now.
    # TODO “$0 -f grid/maman.sdk” freezes
    while args.count > 1
      f = args.first

      if f == '-s'
        params[:singles] = true
        args = args[1..-1]
      elsif f == '-d'
        params[:method] = :deduction
        args = args[1..-1]
      elsif f == '-c'
        params[:chains] = true
        args = args[1..-1]
      elsif f == '-g'
        params[:method] = :guess
        args = args[1..-1]
      # No tree yet.
      end
    end

    args.each do |arg|
      solver = SudokuSolver.new arg
      solver.print
      if !solver.valid?
        puts "Grid is not valid.  Exiting."
        exit
      end
      solver.solve params
      solver.print
    end
  end
end