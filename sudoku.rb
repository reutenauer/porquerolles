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
  def initialize filename = nil
    if filename
      @grid = parse_file filename
    else
      @grid = Hash.new
      9.times do |i|
        9.times do |j|
          @grid[[i, j]] = Cell.new
        end
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

  def parse_file filename
    begin
      gridfile = File.open filename, "r"
    rescue Errno::ENOENT
      puts "Error: could not open file #{filename}."
      exit -1
    end

    grid = Hash.new
    i = 0
    gridfile.each do |line|
      if i == 9
        break
      end
      line =~ /(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)(\d[^\d]*)/ # TODO: simplify!
      if match # TODO Simplify that as well :-)
        grid[[i, 0]] = $1
        grid[[i, 1]] = $2
        grid[[i, 2]] = $3
        grid[[i, 3]] = $4
        grid[[i, 4]] = $5
        grid[[i, 5]] = $6
        grid[[i, 6]] = $7
        grid[[i, 7]] = $8
        grid[[i, 8]] = $9
        i = i + 1
      end
    end

    if i != 9
      puts "Error: could not input grid from file #{filename}."
    end
  end
end

solver = SudokuSolver.new
solver.solve
