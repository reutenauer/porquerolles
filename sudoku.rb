#!/usr/bin/env ruby

class Cell
  def initialize x = nil
    @possible_values = []

    if x
      @value = x
      @solved = true
    else
      @value = nil
      9.times { |i| @possible_values << i }
      @solved = false
    end
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

  def include? x
    @cells.include? x
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

  def include? x
    @cells.include? x
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

  def include? x
    @cells.include? x
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
    9.times { |k| @blocks << (Block.new k) }
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
    @grid.each do |coord, cell|
      if not cell.solved?
        return false
      end
      true
    end
  end

  def propagate
    check_constraints
  end

  def search i
    (@rows + @columns + @blocks).each do |group|
      group.search i
    end
  end

  def solve
    @old_grid = @grid
    while !solved?
      propagate
      1.upto(9) { |n| search n }
      if @grid == @old_grid
        break
      end
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

    def set_cell grid, i, j, x
      if x == "."
        grid[[i, j]] = Cell.new
      else
        grid[[i, j]] = Cell.new x
      end
    end

    grid = Hash.new
    i = 0
    gridfile.each do |line|
      if i == 9
        break
      end
      match = line =~ /(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*(\d|\.)[^\d]*/ # TODO: simplify!

      if match # TODO Simplify that as well :-)
        set_cell grid,  i, 0, $1
        set_cell grid,  i, 1, $2
        set_cell grid,  i, 2, $3
        set_cell grid,  i, 3, $4
        set_cell grid,  i, 4, $5
        set_cell grid,  i, 5, $6
        set_cell grid,  i, 6, $7
        set_cell grid,  i, 7, $8
        set_cell grid,  i, 8, $9
        i = i + 1
      end
    end

    if i != 9
      puts "Error: could not input grid from file #{filename}."
    end

    grid
  end

  def print
    9.times do |i|
      row = ""
      9.times do |j|
        row = "#{row}#{@grid[[i, j]].solved? ? @grid[[i, j]].get_value : '.'}"
      end
      puts row
    end
  end
end

solver = SudokuSolver.new ARGV[0]
solver.solve
