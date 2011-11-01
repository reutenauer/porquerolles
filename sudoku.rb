#!/usr/bin/env ruby

require 'rubygems'
require 'ruby-debug'

class Array
  def second
    at(1)
  end
end

class Cell
  def initialize x = nil
    @possible_values = []

    if x
      @value = x.to_i
      @solved = true
    else
      @value = nil
      1.upto(9) { |i| @possible_values << i }
      @solved = false
    end
  end

  def get_value
    @value
  end

  def cross_out x
    if x.class == Fixnum
      x = [x]
    end
    @possible_values = @possible_values - x
  end

  def check_solved
    if @possible_values.count == 1
      @solved = true
      @value = @possible_values.first
    end
  end

  def set_solved x
    @value = x
    @solved = true
    @possible_values = [x]
  end

  def get_possible_values
    @possible_values
  end

  def solved?
    @solved
  end
end

class Group
  def initialize_group
    @coords = []
    @possible_locations = { }
    1.upto(9) do |x|
      @possible_locations[x] = []
    end
  end

  def get_coords
    @coords
  end

  def include? x
    @coords.include? x
  end

  def add_possible_location x, coord
    @possible_locations[x] << coord
    @possible_locations[x].sort!
  end

  def check_unique_location x
    if @possible_locations[x].count == 1
      return @possible_locations[x].first
    end
    nil
  end
end

class Row < Group
  def initialize i
    initialize_group
    @coords = []
    9.times do |j|
      @coords << [i, j]
    end
  end
end

class Column < Group
  def initialize j
    initialize_group
    @coords = []
    9.times do |i|
      @coords << [i, j]
    end
  end
end

class Block < Group
  def initialize k
    initialize_group
    row_block = 3 * (k / 3)
    col_block = 3 * (k % 3)

    @coords = []
    3.times do |i|
      3.times do |j|
        @coords << [row_block + i, col_block + j]
      end
    end
  end

  def is_on_one_line? type, x
    lines = @possible_locations[x].map(&type).uniq
    if lines.count == 1
      lines.first
    else
      false
    end
  end

  def is_on_one_row? x
    is_on_one_line? :first, x
  end

  def is_on_one_column? x
    is_on_one_line? :second, x
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
      if not this_cell.solved?
        (@rows + @columns + @blocks).each do |group|
          if group.include? this_coord
            this_cell.cross_out(get_values(group))
          end
        end

        if this_coord == [7, 4]
          # debugger
        end
        this_cell.check_solved
      end
    end
  end

  def get_values group
    values = []
    group.get_coords.each do |coord|
      cell = @grid[coord]
      if cell.solved?
        values << cell.get_value
      end
    end
    values
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

  def search_group group, x
    group.get_coords.each do |coord|
      cell = @grid[coord]
      vals = cell.get_possible_values
      if vals.include? x
        group.add_possible_location x, coord
      end
    end

    if group.check_unique_location x
      @grid[(group.check_unique_location x)].set_solved x
    end
  end

  def search_unique_locations x
    (@rows + @columns + @blocks).each do |group|
      search_group group, x
    end
  end

  def search_block_locations x
    @blocks.each_with_index do |block, index|
      i = block.is_on_one_row? x
      if i
        j_to_avoid = index % 3
        9.times do |j|
          if j % 3 != j_to_avoid
            @grid[[i, j]].cross_out x
          end
        end
      else # TODO: rewrite that to avoid duplication
        i = block.is_on_one_row? x
        if i
          i_to_avoid = index / 3
          9.times do |i|
            if j / 3 != i_to_avoid
              @grid[[i, j]].cross_out x
            end
          end
        end
      end
    end
  end

  def search_all
    1.upto(9) { |x| search_unique_locations x }
    # 1.upto(9) { |x| search_block_locations x }
  end

  def nb_cell_solved
    nsolved = 0
    @grid.each_value do |cell|
      if cell.solved?
        nsolved = nsolved + 1
      end
    end
    nsolved
  end

  def solve
    while !solved?
      old_nb_cell_solved = nb_cell_solved
      propagate
      search_all
      if nb_cell_solved == old_nb_cell_solved
        break
      end
    end

    @grid
  end

  def parse_file filename
    puts "Parsing file #{filename}."
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
        set_cell grid, i, 0, $1
        set_cell grid, i, 1, $2
        set_cell grid, i, 2, $3
        set_cell grid, i, 3, $4
        set_cell grid, i, 4, $5
        set_cell grid, i, 5, $6
        set_cell grid, i, 6, $7
        set_cell grid, i, 7, $8
        set_cell grid, i, 8, $9
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
      if i % 3 == 0
        puts "+---+---+---+"
      end
      row = ""
      9.times do |j|
        if j % 3 == 0
          row = "#{row}|"
        end
        row = "#{row}#{@grid[[i, j]].solved? ? @grid[[i, j]].get_value : '.'}"
      end
      row = "#{row}|"
      puts row
    end
   puts "+---+---+---+"
  end
end
