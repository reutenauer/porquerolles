#!/usr/bin/env ruby

# UTF-8, 108 characters a line (more comfortable than 72/80).

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
      @possible_values = Set.new [x.to_i]
    else
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
    @possible_values.first
  end

  def cross_out x, dbg
    # debugger if dbg == [1, 2] && x.is_a?(Array) && x.include?(5)
    if x.class == Fixnum
      x = [x]
    end
    @possible_values = @possible_values - x
  end

  def set_solved x
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
    @grid.each do |coord, cell|
      return false unless cell.solved?
    end
    true
  end

  def propagate
    @grid.each do |coord, cell|
      unless cell.solved?
        (@rows + @columns + @blocks).each do |group|
          # debugger if coord == [1, 2] && cell.possible_values == Set.new([5])
	  debugger if coord == [1, 2] && values(group, coord).include?(5) && group.include?(coord)
          cell.cross_out values(group, coord), coord if group.include? coord
        end
      end
    end
  end

  def possible_locations group, x
    group.coords.map do |coord| # TODO Some map that yields both coord and cell as as an enumerator?
      cell = @grid[coord]
      coord if cell.possible_values.include? x # TODO Cell.include method?
    end.compact
  end

  def is_on_one_line? group, type, x
    locs = possible_locations group, x
    lines = locs.map(&type).uniq
    if lines.count == 1
      lines.first
    else
      false
    end
  end

  def is_on_one_row? block, x
    is_on_one_line? block, :first, x
  end

  def is_on_one_column? block, x
    is_on_one_line? block, :second, x
  end

  def search_group group, x
    # debugger if group.coords == [[0, 2], [1, 2], [2, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [8, 2]] && x == 5
    locs = possible_locations(group, x)
    if locs.count == 1
      # debugger if locs.first == [4, 2]
      @grid[locs.first].set_solved x
    end
  end

  def search_unique_locations x
    (@rows + @columns + @blocks).each do |group|
      search_group group, x
    end
  end

  # TODO: rewrite the three functions below to avoid duplication
  def search_block_locations x
    @blocks.each_with_index do |block, index|
      i = is_on_one_row? block, x
      if i
        j_to_avoid = index % 3
        9.times do |j|
          if j / 3 != j_to_avoid
            @grid[[i, j]].cross_out x, [i, j]
          end
        end
      else
        j = is_on_one_column? block, x
        if j
          i_to_avoid = index / 3
          9.times do |i|
            if i / 3 != i_to_avoid
              @grid[[i, j]].cross_out x, [i, j]
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
          next if ioff + i == b
          3.times do |j|
            @grid[[ioff + i, joff + j]].cross_out x, [ioff + i, joff + j]
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
            next if joff + j == b
            @grid[[ioff + i, joff + j]].cross_out x, [ioff + i, joff + j]
          end
        end
      end
    end
  end

  def search_group_for_subsets group
    locs = { }
    1.upto(9).each { |x| locs[x] = possible_locations group, x }
    group.coords.each do |coord|
      cell = @grid[coord]
      if cell.solved?
        i = cell.value
        locs[i] = [coord]
      end
    end

    debugger if !1.upto(9).inject(true) { |b, x| b && locs[x].is_a?(Array) }
    unsolved = 1.upto(9).map { |x| x if locs[x].count > 1 }.compact
    # unsolved = 1.upto(9).map { |i| i } - (group.coords.map do |coord|
    #   cell = @grid[coord]
    #   cell.value if cell.solved?
    # end.flatten)

    subsets = unsolved.subsets
    subsets.each do |subset|
      these_locs = subset.inject([]) { |l, x| l + locs[x] }.sort.uniq # TODO set!
      if these_locs.count == subset.count # && subset.count > 1
        values_to_cross_out = unsolved - subset
        these_locs.each do |coord|
          values_to_cross_out.each do |x|
            @grid[coord].cross_out x, coord
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
      search_group_for_subsets group
    end
  end

  def nb_cell_solved
    @grid.each_value.inject(0) do |nsolved, cell|
      nsolved + (cell.solved? ? 1 : 0)
    end
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
        # debugger if [i, j] == [0, 3]
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
