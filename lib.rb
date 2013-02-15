#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'

class Deadlock < Exception
end

class Paradox < Exception
end

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

  def random
    to_a[rand to_a.count]
  end
end

class Hash
  def separate
    Hash.new.tap { |rejected| delete_if { |k, v| yield(k, v) && rejected[k] = v } }
  end
end

class Hypothesis
  def initialize grid, coord, value
    @grid = grid
    @coord = coord
    @value = value
  end

  def grid
    @grid
  end

  def coord
    @coord
  end

  def value
    @value
  end
end

class Node
  def initialize parent, label = nil
    @parent = parent
    @children = []
    @children << Node.new(label) if label
  end

  def add label
    @children << Node.new(label)
  end

  def remove node
    @children.delete_if { |child| child == node }
  end

  def parent
    @parent
  end

  def root
    node = self
    while parent
      node = node.parent
    end

    node
  end

  def each &block
    @children.each &block
  end
end

class Tree < Node
  def initialize
    @children = []
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
    count == 1
  end

  def count
    @values.count
  end

  def to_s
    if solved?
      value.to_s
    else
      "."
    end
  end

  def copy
    Cell.new.tap { |cell| cell.cross_out(1.upto(9).map.to_set - @values) }
  end

  def guess
    set_solved @values.random
  end

  def deadlock?
    count == 0
  end

  def each &block
    @values.each &block
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

  def locations x
    @coords.map do |coord| # TODO Some enumerator that yields both coord and cell as as an enumerator?
      cell = @grid.cell coord
      coord if cell.include? x
    end.compact.to_set
  end

  def place
    locs = { }
    1.upto(9).each do |x|
      locs[x] = locations x
      raise Deadlock if locs[x].count == 0
    end
    unsolved = locs.separate { |x, l| l.count > 1 }

    locs.each do |x, l|
      cell = @grid.cell(l.first)
      raise "No ‘cell’ in Group.place.  This should not happen." unless cell
      cell.set_solved x
    end

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

  def paradox?
    1.upto(9).map do |x|
      cells.map { |cell| cell if cell.solved? && cell.value == x }.compact.count > 1
    end.any?
  end
end

class Row < Group
  def initialize i, grid
    initialize_group grid # TODO make that more OO-like
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

# TODO Rename @grid to @matrix here, otherwise nobody has any chance of
# understanding anything
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

    # TODO: make that a class method!
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

  def map &block
    @grid.map &block
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

  def min
    map do |coord, cell|
      n = cell.count
      n if n > 1
    end.compact.min
  end

  def random
    m = min
    cells = map do |coord, cell|
      [coord, cell] if cell.count == m
      # cell if cell.count == m
    end.compact

    cells[rand cells.count]
  end

  def copy
   Grid.new(
     Hash.new.tap do |hash|
       each do |coord, cell|
         hash[coord] = cell.copy
       end
     end)
  end

  def solved?
    each_value.map(&:solved?).all?
  end

  def deadlock?
    each_value.map(&:deadlock?).any?
  end

  def paradox?
    groups.map(&:paradox?).any?
  end

  def tree
    coord_and_cell = random
    coord = coord_and_cell.first
    cell = coord_and_cell.last
    cell.each do |val|
      grid = copy
      grid[coord].set_solved val
      hypothesis = Hypothesis.new(grid, coord, val)
      @node.add hypothesis
    end

    @node.each do |node|
      node.grid.tree
    end
  end
end

class SudokuSolver
  def initialize filename = nil
    if filename
      @grid = Grid.new parse_file filename
    else
      @grid = Grid.new
    end

    @hypotheses = []
    @node = Tree.new
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

  def place
    @grid.groups.each { |group| group.place }
  end

  def nb_cell_solved
    @grid.each_value.inject(0) { |nsolved, cell| nsolved + (cell.solved? ? 1 : 0) }
  end

  def deduce
    until @grid.solved?
      old_nb_cell_solved = nb_cell_solved
      propagate
      place
      break if nb_cell_solved == old_nb_cell_solved
    end

    raise Paradox if @grid.paradox?
    @grid
  end

  def guess
    grid = @grid.copy
    coord_and_cell = @grid.random
    coord = coord_and_cell.first
    cell = coord_and_cell.last
    val = cell.guess
    @hypotheses << Hypothesis.new(grid, coord, val)
  end

  def tree
    @grid.tree
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

  def backtrack
    raise Paradox if @hypotheses.count == 0
    hypothesis = @hypotheses.pop
    @grid = hypothesis.grid
    coord = hypothesis.coord
    value = hypothesis.value
    cell = @grid.cell coord
    cell.cross_out value
    backtrack if @grid.paradox?
  end

  def valid?
    !@grid.paradox?
  end

  def solve params = { }
    # Possible methods: :deduction, :guess, :tree
    method = params[:method]
    method = :deduction if !method
    begin
      deduce
      if method == :guess
        until @grid.solved?
          begin
            guess
            deduce
            if @grid.deadlock?
              backtrack
            end
          rescue Deadlock
            backtrack
          end
        end
      elsif method == :tree
        tree = @grid.tree
        tree.each do |node|
          node.grid.tree
        end
	# TODO...
      end
    rescue Paradox
      puts "Sudoku insoluble."
    end
  end

  def print
    puts @grid.to_s
  end
end
