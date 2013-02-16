#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'

require File.expand_path('lib', File.dirname(__FILE__))

# Sudoku main.

# TODO tree option, verbose option.
# I’ll play with optparse later.

f = ARGV.first
args = ARGV
params = { }

if f == '-d'
  params = { :method => :deduction }
  args = args[1..-1]
elsif f == '-g'
  params = { :method => :guess }
  args = args[1..-1]
# No tree yet.
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
