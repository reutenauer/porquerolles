#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'

# Sudoku command-line parsing.

# TODO tree option, verbose option.
# I’ll play with optparse later.

module Sudoku
  class Main
    def self.run(args, output = NullOutput.new)
      params = Options.parse(args)

      args.each do |arg|
        solver = Solver.new(output)
        solver.ingest(arg)
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
end
