#!/usr/bin/env ruby

# UTF-8, 108 character a line (more comfortable than 72/80).

require 'rubygems'
require 'ruby-debug'
require 'set'

class Array
  def second
    at(1)
  end

  def subsets
    if empty?
      [[]]
    else
      tail = [last]
      subsubsets = slice(0, count - 1).subsets
      subsubsets + subsubsets.map { |set| set + tail }
    end
  end
end

class Cell
  def initialize x = nil
    if x
      @value = x.to_i
      @possible_values = Set.new [x.to_i]
    else
      @value = nil
      @possible_values = Set.new 1.upto(9).map { |i| i }
    end
  end

  def value
    if @possible_values.count != 1
      debugger
      raise "Requested valued of unsolved cell; aborting (this shouldn’t happen!)."
    end

    if @possible_values.first != @value && @value != nil
      debugger
    end
    # @possible_values.first
    @value
  end

  def cross_out x
    if x.class == Fixnum
      x = [x]
    end
    @possible_values = @possible_values - x

    # TODO!  This obviously does nothing since I forgot the ‘@’ before
    # “value”.  However, if I restore it, some grids that could be
    # solved, can’t be any more.  Find out what happen!
    # There must be a nasty bug somewhere...
    if @possible_values.count == 1
      value = @possible_values.first
    end
  end

  def check_solved
    if @possible_values.count == 1
      @value = @possible_values.first
    end
  end

  def set_solved x
    @value = x
    @possible_values = Set.new [x]
  end

  def possible_values
    @possible_values
  end

  def solved?
    @possible_values.count == 1
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

  def flush_possible_locations x = nil
    if x
      @possible_locations[x] = []
    else
      1.upto(9) do |x|
        @possible_locations[x] = []
      end
    end
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

  def possible_locations
    @possible_locations
  end
end

class Row < Group
  def initialize i
    initialize_group
    @coords = 9.times.map { |j| [i, j] }
  end

  def is_in_one_block? x
    locs = @possible_locations[x].map { |c| c[1] / 3 }.uniq
    if locs.count == 1
      locs.first
    else
      false
    end
  end
end

class Column < Group
  def initialize j
    initialize_group
    @coords = 9.times.map { |i| [i, j] }
  end

  def is_in_one_block? x
    locs = @possible_locations[x].map { |c| c[0] / 3 }.uniq
    if locs.count == 1
      locs.first
    else
      false
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

    @rows = 9.times.map { |i| Row.new i }
    @columns = 9.times.map { |j| Column.new j }
    @blocks = 9.times.map { |k| Block.new k }
  end

  def values group
    group.coords.map do |coord|
      cell = @grid[coord]
      cell.value if cell.solved?
    end.compact
  end

  def solved?
    @grid.each do |coord, cell|
      unless cell.solved?
        return false
      end
    end
    true
  end

  def propagate
    @grid.each do |this_coord, this_cell|
      unless this_cell.solved?
        (@rows + @columns + @blocks).each do |group|
          if group.include? this_coord
            this_cell.cross_out(values(group))
          end
        end
        this_cell.check_solved # TODO: suppress need for that, and the method in Cell.
      end
    end
  end

  def compute_locations group, x
    group.coords.each do |coord|
      cell = @grid[coord]
      vals = cell.possible_values
      if vals.include? x
        group.add_possible_location x, coord
      end
    end
  end

  def search_group group, x
    if group.check_unique_location x
      @grid[(group.check_unique_location x)].set_solved x
    end
  end

  def search_unique_locations x
    (@rows + @columns + @blocks).each do |group|
      group.flush_possible_locations x
      compute_locations group, x
    end

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
          if j / 3 != j_to_avoid
            @grid[[i, j]].cross_out x
          end
        end
      else # TODO: rewrite that to avoid duplication
        j = block.is_on_one_column? x
        if j
          i_to_avoid = index / 3
          9.times do |i|
            if i / 3 != i_to_avoid
              @grid[[i, j]].cross_out x
            end
          end
        end
      end
    end
  end

  def search_row_locations x
    @rows.each_with_index do |row, index|
      b = row.is_in_one_block? x
      ioff = 3 * (index / 3)
      joff = 3 * (index % 3)
      if b
        3.times do |i|
          if ioff + i == b
            next
          end
          3.times do |j|
            @grid[[ioff + i, joff + j]].cross_out x
          end
        end
      end
    end
  end

  def search_column_locations x
    @columns.each_with_index do |column, index|
      b = column.is_in_one_block? x
      ioff = 3 * (index / 3)
      joff = 3 * (index % 3)
      if b
        3.times do |i|
          3.times do |j|
            if joff + j == b
              next
            end
            @grid[[ioff + i, joff + j]].cross_out x
          end
        end
      end
    end
  end

  def search_group_for_subsets group
    locs = group.possible_locations
    unsolved = []
    1.upto(9) do |x|
      if locs[x].count > 1
        unsolved << x
      end
    end

    subsets = unsolved.subsets
    subsets.each do |subset|
      these_locs = subset.inject([]) { |l, x| l + locs[x] }.sort.uniq
      if these_locs.count == subset.count # && subset.count > 1
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
    1.upto(9) do |x|
        search_unique_locations x
        search_block_locations x
    end

    (@rows + @columns + @blocks).each do |group|
      # 1.upto(9) { |x| compute_locations group, x }
      search_group_for_subsets group
    end
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
