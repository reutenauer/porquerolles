#!/usr/bin/env ruby

class Cell
  def initialize
    @solved = false
    @possible_values = []
    1.upto(9) { |i| @possible_values << i }
    @value = nil
  end

  def get_value
    @value
  end

  def cross_out x
    @possible_figures = @possible_figures - x
  end

  def check_solved
    if @possible_values.count == 1
      @solved = true
      value = @possible_values.first
    end
  end

  def solved?
    @solved
  end
end

class Row
  def initialize i
    @cells = []
    1.upto(9) do |j|
      @cells << [i, j]
    end
  end

  def search i
  end
end

class Column
  def initialize j
    @cells = []
    1.upto(9) do |i|
      @cells << [i, j]
    end
  end

  def search i
  end
end

class Block
  def initialize k
    # TODO
  end

  def search i
  end
end

class Grid
  def initialize
    @hash = Hash.new
    1.upto(9) do |i|
      1.upto(9) do |j|
        @hash[[i, j]] = Cell.new
      end
    end
  end

  def [] i, j
    @hash[[i, j]]
  end
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

  def check_constraints
    @grid.each do |this_coord, this_cell|
      (@rows + @columns + @blocks).each do |group|
        if group.include? @coordinates
          group.each do |that_coord|
            that_cell = @grid[that_coord]
            if that_cell.solved?
              this_cell.cross_out(that_cell.get_value)
            end
          end
        end
      end

      this_cell.check_solved
    end
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
