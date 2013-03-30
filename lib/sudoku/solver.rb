#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'
require 'debugger'
require 'optparse'

# TODO exit -1 when applicable.
module Sudoku
  class Solver
    attr_reader :grid
    attr_reader :output

    def initialize(output = NullOutput.new)
      @output = output
      @grid = Grid.new
      @hypotheses = []
      @node = Tree.new
      @params = { }
    end

    def parse_options(args)
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] <file name>"

        opts.on('-s', "--[no]-singles", "Place single candidates") do |s|
          @params[:singles] = s
        end

        opts.on('-d', "--deduction", "Use deduction method") do
          @params[:method] = :deduction
        end

        opts.on('-c', "--[no-]chains", "Find chains") do |c|
          @params[:chains] = c
        end

        opts.on('-g', "--guess", "Use guess method") do
          @params[:method] = :guess
        end

        opts.on('-v', "--[no-]verbose", "Be more verbose") do |v|
          @params[:verbose] = v
        end

        opts.on('-q', "--[no-]quiet", "Be quieter") do |q|
          # Note: if we only use the key :verbose, the defaults are correct (i. e., quiet).
          @params[:verbose] = !q
        end

        # No tree yet.

        begin
          opts.parse!(args)
        rescue OptionParser::InvalidOption => message
          @output.puts "Error: #{message}"
          @output.puts opts
        end
      end
    end

    def ingest(filename)
      @grid = Grid.new(parse_file(filename), self)
    end

    def verbose?
      @params[:verbose] if @params
    end

    def chains?
      @params[:chains] if @params
    end

    def propagate
      @grid.each do |coord, cell|
        unless cell.solved?
          @grid.groups.each do |group|
            cell.cross_out(group.values(cell)) if group.include? coord
          end
        end
      end
    end

    def place
      @grid.groups.each { |group| group.place(@params) }
    end

    def find_chains
      @grid.find_chains.each do |chain|
        x = chain[0]
        upper_loc = chain[1].first
        lower_loc = chain[1].last
        group = chain[2]
        group.each do |coord|
          next if coord == upper_loc || coord == lower_loc
          @grid.cell(coord).cross_out(x)
        end
      end
    end

    def nb_cell_solved
      @grid.each_value.inject(0) do |nsolved, cell|
        nsolved + if cell.solved? then 1 else 0 end
      end
    end

    def deduce
      until @grid.solved?
        old_nb_cell_solved = nb_cell_solved
        propagate
        place
        find_chains if @params[:chains]
        break if nb_cell_solved == old_nb_cell_solved
      end

      raise Paradox if @grid.paradox?
    end

    def guess
      @nb_hypotheses += 1 # FIXME That’s ridiculous.  Use @hypotheses.count
      grid = @grid.copy
      coord_and_cell = @grid.random
      coord = coord_and_cell.first
      cell = coord_and_cell.last
      val = cell.guess
      @hypotheses << Hypothesis.new(grid, coord, val)
    end

    def tree
      @grid.tree
    end

    # TODO Method to cross out value x from group1 when there is a group2 such that
    # group1.locations(x) is contained in group2.  Probably was there at some point.

    def parse_file(filename)
      @output.puts "Parsing file #{filename}."
      begin
        gridfile = File.open(filename, "r")
      rescue Errno::ENOENT
        @output.puts "Error: could not open file #{filename}."
        exit -1
      end

      # TODO Refactor that
      def self.set_cell(grid, i, j, x)
        x = nil if x == "."
        grid[[i, j]] = Cell.new(x)
      end

      grid = Hash.new
      i = 0
      gridfile.each do |line| # TODO Rescue Errno::EISDIR
        if i == 9
          break
        end
        match = line.scan /\d|\./

        if match.count == 9
          9.times do |j|
            set_cell(grid, i, j, match[j])
          end

          i = i + 1
        end
      end

      if i != 9
        @output.puts "Error: could not input grid from file #{filename}."
      end

      grid
    end

    def backtrack
      raise Paradox if @hypotheses.count == 0
      hypothesis = @hypotheses.pop
      @grid = hypothesis.grid
      coord = hypothesis.coord
      value = hypothesis.value
      cell = @grid.cell coord
      cell.cross_out value
      backtrack if @grid.paradox?
    end

    def valid?
      !@grid.paradox?
    end

    def solve
      # Possible methods: :deduction, :guess, :tree
      method = @params[:method]
      method = :deduction unless method
      begin
        deduce
        if method == :guess
          @nb_hypotheses = 0
          @output.puts "Entering guessing mode ..."
          until @grid.solved?
            begin
	      @output.print "\rConsidered #{@nb_hypotheses} hypotheses so far.  Hypothesis depth: #{@hypotheses.count}."
              guess
              deduce
              if @grid.deadlock?
                backtrack
              end
            rescue Deadlock
              backtrack
            end
          end
        elsif method == :tree
          tree = @grid.tree
          tree.each do |node|
            node.grid.tree
          end
	  # TODO...
        end
      rescue Paradox
        @output.puts "Sudoku insoluble."
      end
      @output.puts "  Solved!" if method == :guess and nb_cell_solved == 81
    end

    def print
      @output.puts @grid.display
    end

    def solved?
      grid.solved?
    end

    def run(args)
      parse_options(args)

      args.each do |arg|
        ingest(arg)
        print
        unless valid?
          puts "Grid is not valid.  Exiting."
          exit
        end
        solve
        print
      end
    end
  end
end
