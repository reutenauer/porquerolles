#!/usr/bin/env ruby

class Cell
  def check_constraints
  end
end

class Row
  def search i
  end
end

class Column
  def search i
  end
end

class Block
  def search i
  end
end

class Grid
end

class SudokuSolver
  def initialize
    # Initialize grid
    @grid = Grid.new
    @cells = []
    @rows = []
    @columns = []
    @blocks = []
  end

  def solved?
    true
  end

  def propagate
    @cells.each do |cell|
      cell.check_constraints
    end
  end

  def reduce
    @cells.each do |cell|
      cell.reduce
    end
  end

  def search i
    (@rows + @columns + @blocks).each do |group|
      group.search i
    end
  end

  def solve
    while !solved?
      propagate
      reduce
      1.upto(9) { |i| search i }
      reduce
    end

    @grid
  end
end

solver = SudokuSolver.new
solver.solve
