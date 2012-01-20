#!/usr/bin/env ruby

# UTF-8, 108 characters a line (more comfortable than 72/80).

require 'rubygems'
require 'ruby-debug'
require 'set'

class Set
  # Method to pick one element in a standard-library set.  A little pedestrian, but fun!
  def pick
    first # Declared here so as to avoid a global variable (that would be BAD!)
    each do |element|
      first = element
      break
    end
    first
  end

  # Lists subsets.  Recursive.  A classic.
  def subsets
    if empty?
      return Set.new [Set.new]
    else
      head = Set.new [pick]
      subsubsets = (self - head).subsets
      return subsubsets + Set.new(subsubsets.map { |set| set + head })
    end
  end
end

class Hash
  def separate
    Hash.new.tap { |rejected| delete_if { |k, v| yield(k, v) && rejected[k] = v } }
  end
end

class Cell
  def initialize x = nil
    if x
      @values = Set.new [x.to_i]
    else
      @values = Set.new 1.upto(9).map { |i| i }
    end
  end

  def value
    if @values.count != 1
      raise "Requested valued of unsolved cell; aborting (this shouldn’t happen!)."
    end

    @values.first
  end

  def cross_out x
    x = [x] if x.class == Fixnum
    @values = @values - x
  end

  def set_solved x
    @values = Set.new [x]
  end

  def include? x
    @values.include? x
  end

  def solved?
    @values.count == 1
  end

  def to_s
    if solved?
      value.to_s
    else
      "."
    end
  end
end

class Group
  def initialize_group grid
    @grid = grid
    @coords = []
  end

  def coords
    @coords
  end

  def cells
    @coords.map { |coord| @grid.cell coord }
  end

  def include? x
    @coords.include? x
  end

  def values exclude = nil
    cells.map do |cell|
      cell.value if cell != exclude && cell.solved?
    end.compact
  end

  def possible_locations x
    @coords.map do |coord| # TODO Some enumerator that yields both coord and cell as as an enumerator?
      cell = @grid.cell coord
      coord if cell.include? x
    end.compact.to_set
  end

  def locate
    locs = { }
    1.upto(9).each { |x| locs[x] = possible_locations x }
    unsolved = locs.separate { |x, l| l.count > 1 }

    locs.each { |x, l| @grid.cell(l.first).set_solved x }

    unsolved_values = unsolved.each_key.to_set
    subsets = unsolved_values.subsets
    subsets.each do |subset|
      these_locs = subset.inject(Set.new) { |l, x| l + unsolved[x] }
      if these_locs.count == subset.count
        values_to_cross_out = unsolved_values - subset
        these_locs.each do |coord|
          @grid.cell(coord).cross_out values_to_cross_out
        end
      end
    end
  end
end

class Row < Group
  def initialize i, grid
    initialize_group grid
    @coords = 9.times.map { |j| [i, j] }
  end
end

class Column < Group
  def initialize j, grid
    initialize_group grid
    @coords = 9.times.map { |i| [i, j] }
  end
end

class Block < Group
  def initialize k, grid
    initialize_group grid
    row_block = 3 * (k / 3)
    col_block = 3 * (k % 3)

    @coords = []
    3.times do |i|
      3.times do |j|
        @coords << [row_block + i, col_block + j]
      end
    end
  end
end

class Grid
  def initialize grid = nil
    if grid
      @grid = grid
    else
      @grid = Hash.new
      9.times do |i|
        9.times do |j|
          @grid[[i, j]] = Cell.new
        end
      end
    end

    @rows = 9.times.map { |i| Row.new i, self }
    @columns = 9.times.map { |j| Column.new j, self }
    @blocks = 9.times.map { |k| Block.new k, self }
  end

  def cell loc
    @grid[loc]
  end

  def rows
    @rows
  end

  def columns
    @columns
  end

  def blocks
    @blocks
  end

  def groups
    @rows + @columns + @blocks
  end

  def each &block
    @grid.each &block
  end

  def each_key &block
    @grid.each_key &block
  end

  def each_value &block
    @grid.each_value &block
  end

  def [] i, j
    @grid[[i, j]]
  end

  def to_s
    s = ""
    9.times do |i|
      if i % 3 == 0
        s = s + "+---+---+---+\n"
      end
      row = ""
      9.times do |j|
        if j % 3 == 0
          row = "#{row}|"
        end
        row = "#{row}#{self[i, j].to_s}"
      end
      row = "#{row}|"
      s = s + row + "\n"
    end
   s = s + "+---+---+---+\n"
  end
end

class SudokuSolver
  def initialize filename = nil
    if filename
      @grid = Grid.new parse_file filename
    else
      @grid = Grid.new
    end
  end

  def solved?
    @grid.each_value.map(&:solved?).all?
  end

  def propagate
    @grid.each do |coord, cell|
      unless cell.solved?
        @grid.groups.each do |group|
          cell.cross_out group.values cell if group.include? coord
        end
      end
    end
  end

  def locate
    @grid.groups.each { |group| group.locate }
  end

  def nb_cell_solved
    @grid.each_value.inject(0) { |nsolved, cell| nsolved + (cell.solved? ? 1 : 0) }
  end

  def solve
    until solved?
      old_nb_cell_solved = nb_cell_solved
      propagate
      locate
      break if nb_cell_solved == old_nb_cell_solved
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
      x = nil if x == "."
      grid[[i, j]] = Cell.new x
    end

    grid = Hash.new
    i = 0
    gridfile.each do |line|
      if i == 9
        break
      end
      match = line.scan /\d|\./

      if match.count == 9
        9.times do |j|
          set_cell grid, i, j, match[j]
        end

        i = i + 1
      end
    end

    if i != 9
      puts "Error: could not input grid from file #{filename}."
    end

    grid
  end

  def grid
    @grid
  end
end

ARGV.each do |arg|
  solver = SudokuSolver.new arg
  puts solver.grid.to_s
  grid = solver.solve
  puts solver.solved?
  puts grid.to_s
end
