#!/usr/bin/env ruby

class Cell
  def initialize
    @solved = false
    @possible_values = []
    9.times { |i| @possible_values << i }
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
    9.times do |j|
      @cells << [i, j]
    end
  end

  def search x
  end
end

class Column
  def initialize j
    @cells = []
    9.times do |i|
      @cells << [i, j]
    end
  end

  def search x
  end
end

class Block
  def initialize k
    row_block = 3 * (k / 9)
    col_block = 3 * (k % 9)

    @cells = []
    3.times do |i|
      3.times do |j|
        @cells << [row_block + i, col_block + j]
      end
    end
  end

  def search i
  end
end

class SudokuSolver
  def initialize
    @grid = Hash.new
    9.times do |i|
      9.times do |j|
        @grid[[i, j]] = Cell.new
      end
    end

    @rows = []
    9.times { |i| @rows << (Row.new i) }
    @columns = []
    9.times { |j| @columns << (Column.new j) }
    @blocks = []
  end

  def check_constraints
    @grid.each do |this_coord, this_cell|
      (@rows + @columns + @blocks).each do |group|
        if group.include? @this_coord
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
      9.times { |i| search i }
      reduce
    end

    @grid
  end
end

solver = SudokuSolver.new
solver.solve
