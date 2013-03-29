#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'
require 'debugger'

module Sudoku
  class Solver
    attr_reader :grid

    def initialize
      @grid = Grid.new
      @hypotheses = []
      @node = Tree.new
    end

    def ingest(filename)
      @grid = Grid.new(Solver.parse_file(filename))
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
      @nb_hypotheses += 1
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

    def self.parse_file(filename)
      puts "Parsing file #{filename}."
      begin
        gridfile = File.open(filename, "r")
      rescue Errno::ENOENT
        puts "Error: could not open file #{filename}."
        exit -1
      end

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
            Solver.set_cell(grid, i, j, match[j])
          end

          i = i + 1
        end
      end

      if i != 9
        puts "Error: could not input grid from file #{filename}."
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

    def solve(params = { })
      @params = params

      # Possible methods: :deduction, :guess, :tree
      method = params[:method]
      method = :deduction unless method
      begin
        deduce
        if method == :guess
          @nb_hypotheses = 0
          puts "Entering guessing mode ..."
          until @grid.solved?
            begin
	      Kernel.print "\rConsidered #{@nb_hypotheses} hypotheses so far.  Hypothesis depth: #{@hypotheses.count}."
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
        puts "Sudoku insoluble."
      end
      puts "  Solved!" if method == :guess and nb_cell_solved == 81
    end

    def print
      puts @grid.display
    end
  end
end
