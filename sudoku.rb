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
      return Set.new([Set.new([])])
    else
      head = Set.new [pick]
      subsubsets = (self - head).subsets
      return subsubsets + Set.new(subsubsets.map { |set| set + head })
    end
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
    if x.class == Fixnum
      x = [x]
    end
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
end

class Group
  def initialize_group
    @coords = []
    @possible_locations = { }
    1.upto(9) do |x|
      @possible_locations[x] = []
    end
  end

  def coords
    @coords
  end

  def include? x
    @coords.include? x
  end
end

class Row < Group
  def initialize i
    initialize_group
    @coords = 9.times.map { |j| [i, j] }
  end
end

class Column < Group
  def initialize j
    initialize_group
    @coords = 9.times.map { |i| [i, j] }
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

    @rows = 9.times.map { |i| Row.new i }
    @columns = 9.times.map { |j| Column.new j }
    @blocks = 9.times.map { |k| Block.new k }
  end

  def values group, exclude = nil
    group.coords.map do |coord|
      cell = @grid[coord]
      cell.value if cell.solved? && coord != exclude
    end.compact
  end

  def solved?
    @grid.each_value.map(&:solved?).all?
  end

  def propagate
    @grid.each do |coord, cell|
      unless cell.solved?
        (@rows + @columns + @blocks).each do |group|
          cell.cross_out values(group, coord) if group.include? coord
        end
      end
    end
  end

  def possible_locations group, x
    group.coords.map do |coord| # TODO Some enumerator that yields both coord and cell as as an enumerator?
      cell = @grid[coord]
      coord if cell.include? x
    end.compact
  end

  def search_group group, x
    locs = possible_locations(group, x)
    if locs.count == 1
      @grid[locs.first].set_solved x
    end
  end

  def search_unique_locations x
    (@rows + @columns + @blocks).each { |group| search_group group, x }
  end

  def search_group_for_subsets group
    locs = { }
    1.upto(9).each { |x| locs[x] = possible_locations group, x }
    unsolved = 1.upto(9).map { |x| x if locs[x].count > 1 }.compact.to_set
    subsets = unsolved.subsets

    subsets.each do |subset|
      these_locs = subset.inject(Set.new([])) { |l, x| l + locs[x] } # TODO set!
      if these_locs.count == subset.count
        values_to_cross_out = unsolved - subset
        these_locs.each do |coord|
          values_to_cross_out.each do |x|
            @grid[coord].cross_out x
          end
        end
      end
    end
  end

  def search_all
    1.upto(9) { |x| search_unique_locations x }
    (@rows + @columns + @blocks).each { |group| search_group_for_subsets group }
  end

  def nb_cell_solved
    @grid.each_value.inject(0) { |nsolved, cell| nsolved + (cell.solved? ? 1 : 0) }
  end

  def solve
    until solved?
      old_nb_cell_solved = nb_cell_solved
      propagate
      search_all
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
        row = "#{row}#{@grid[[i, j]].solved? ? @grid[[i, j]].value : '.'}"
      end
      row = "#{row}|"
      puts row
    end
   puts "+---+---+---+"
  end
end

ARGV.each do |arg|
  solver = SudokuSolver.new arg
  solver.print
  solver.solve
  puts solver.solved?
  solver.print
end
