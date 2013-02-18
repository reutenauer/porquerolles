#!/usr/bin/env ruby
# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'
require 'debugger'

class Deadlock < Exception
end

class Paradox < Exception
end

class Set
  # Lists subsets.  Recursive.  A classic.
  def subsets
    if empty?
      Set.new([Set.new])
    else
      head = Set.new([first])
      subsubsets = (self - head).subsets
      subsubsets + Set.new(subsubsets.map { |set| set + head })
    end
  end

  def random
    to_a[rand(to_a.count)]
  end
end

class Hash
  def separate
    Hash.new.tap { |rejected| delete_if { |k, v| yield(k, v) && rejected[k] = v } }
  end
end

class Hypothesis
  attr_reader :grid, :coord, :value

  def initialize(grid, coord, value)
    @grid = grid
    @coord = coord
    @value = value
  end
end

class Node
  attr_reader :parent

  def initialize(parent, label = nil)
    @parent = parent
    @children = []
    @children << Node.new(label) if label
  end

  def add(label)
    @children << Node.new(label)
  end

  def remove(node)
    @children.delete_if { |child| child == node }
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
  def initialize(x = nil)
    if x
      @values = Set.new([x.to_i])
    else
      @values = Set.new(1.upto(9))
    end
  end

  def value
    if @values.count != 1
      raise "Requested valued of unsolved cell; aborting (this shouldn’t happen!)."
    end

    @values.first
  end

  # Cross out a single value or an array from the cell
  def cross_out(x)
    x = [x] if x.class == Fixnum
    @values = @values - x
  end

  def set_solved(x)
    @values = Set.new([x])
  end

  def include?(x)
    @values.include?(x)
  end

  def solved?
    count == 1
  end

  def count
    @values.count
  end

  def display
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
    set_solved(@values.random)
  end

  def deadlock?
    count == 0
  end

  def each &block
    @values.each &block
  end
end

class Group
  attr_reader :coords

  def initialize_group(grid)
    @grid = grid
    @coords = []
  end

  def cells
    @coords.map { |coord| @grid.cell coord }
  end

  def include? x
    @coords.include? x
  end

  def values(exclude = nil)
    cells.map do |cell|
      cell.value if cell != exclude && cell.solved?
    end.compact
  end

  def locations(x)
    @coords.map do |coord| # TODO Some enumerator that yields both coord and cell as as an enumerator?
      cell = @grid.cell coord
      coord if cell.include? x
    end.compact.to_set
  end

  def place(params = { })
    # TODO: Better than that.  Maybe an method in Group, matched by the
    # real one in Block.  Could take an optional number or range.
    if params[:singles] && (self.is_a? Block) # Brackets needed here for syntax.
      @grid.blocks.each do |block|
        1.upto(9) do |x|
          place_single(x)
        end
      end
    end

    locs = { }
    1.upto(9).each do |x|
      locs[x] = locations x
      raise Deadlock if locs[x].count == 0
    end
    unsolved = locs.separate { |x, l| l.count > 1 }

    locs.each do |x, l|
      cell = @grid.cell(l.first)
      raise "No ‘cell’ in Group.place.  This should not happen." unless cell
      cell.set_solved(x)
    end

    unsolved_values = unsolved.each_key.to_set
    subsets = unsolved_values.subsets
    subsets.each do |subset|
      these_locs = subset.inject(Set.new) { |l, x| l + unsolved[x] }
      if these_locs.count == subset.count
        values_to_cross_out = unsolved_values - subset
        these_locs.each do |coord|
          @grid.cell(coord).cross_out(values_to_cross_out)
        end
      end
    end
  end

  def paradox?
    1.upto(9).any? do |x|
      cells.map { |cell| cell if cell.solved? && cell.value == x }.compact.count > 1
    end
  end
end

class Row < Group
  def initialize(i, grid)
    initialize_group(grid) # TODO make that more OO-like
    @coords = 9.times.map { |j| [i, j] }
  end

  def name
    "Row #{@coords.first.first}"
  end
end

class Column < Group
  def initialize(j, grid)
    initialize_group(grid)
    @coords = 9.times.map { |i| [i, j] }
  end

  def name
    "Column #{@coords.last.last}"
  end
end

class Block < Group
  def initialize(k, grid)
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

  def place_single(x)
    possible_locs = coords.select do |coord|
      cell = @grid.cell(coord)
      coord if cell.include? x
    end

    if possible_locs.count == 1
      coord = possible_locs.first
      @grid.cell(coord).set_solved(x)

      # Propagate the knowledge.
      row = @grid.rows[coord.first]
      col = @grid.columns[coord.last]
      block = @grid.blocks[3 * (coord.first / 3) + coord.last / 3]

      [row, col, block].each do |group|
        group.coords.each do |coord2|
          @grid.cell(coord2).cross_out(x) unless coord2 == coord
        end
      end
    end
  end

  def name
    first_coord = @coords.first
    k = 3 * (first_coord.first / 3) + first_coord.last / 3
    "Block #{k}"
  end
end

class Grid
  attr_reader :rows, :columns, :blocks

  def initialize(grid = nil)
    if grid
      @matrix = grid
    else
      @matrix = Hash.new
      9.times do |i|
        9.times do |j|
          @matrix[[i, j]] = Cell.new
        end
      end
    end

    # TODO: make that a class method!
    @rows = 9.times.map { |i| Row.new i, self }
    @columns = 9.times.map { |j| Column.new j, self }
    @blocks = 9.times.map { |k| Block.new k, self }
  end

  def cell(loc)
    @matrix[loc]
  end

  def groups
    @rows + @columns + @blocks
  end

  def each &block
    @matrix.each &block
  end

  def each_key &block
    @matrix.each_key &block
  end

  def each_value &block
    @matrix.each_value &block
  end

  def map &block
    @matrix.map &block
  end

  def [] i, j
    @matrix[[i, j]]
  end

  def row_of(coord)
    @rows[coord.first]
  end

  def column_of(coord)
    @columns[coord.last]
  end

  def block_of(coord)
    @blocks[3 * (coord.first / 3) + coord.last / 3]
  end

  def groups_of(coord)
    Set.new([row_of(coord), column_of(coord), block_of(coord)])
  end

  def display
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
        row = "#{row}#{self[i, j].display}"
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

    cells[rand(cells.count)]
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
    each_value.all?(&:solved?)
  end

  def deadlock?
    each_value.any?(&:deadlock?)
  end

  def paradox?
    groups.any?(&:paradox?)
  end

  def tree
    coord_and_cell = random
    coord = coord_and_cell.first
    cell = coord_and_cell.last
    cell.each do |val|
      grid = copy
      grid[coord].set_solved(val)
      hypothesis = Hypothesis.new(grid, coord, val)
      @node.add(hypothesis)
    end

    @node.each do |node|
      node.grid.tree
    end
  end

  def find_chains(chains = [], links = nil)
    if links # Chain building has already started
      x = links[0]
      upper_loc = links[1].first
      lower_loc = links[1].last
      upper_chain = links[2].first
      lower_chain = links[2].last
      upper_group = links[2].first.last
      lower_group = links[2].last.last

      if upper_chain.count == 17
        print "Chain of length 17: "
        puts upper_chain.map { |group| group.name }.join(" ")
      end

      all_upper_groups = upper_chain.to_set
      all_lower_groups = lower_chain.to_set

      next_upper_groups = groups_of(upper_loc) - all_upper_groups # groups_of returns a set.
      next_lower_groups = groups_of(lower_loc) - all_lower_groups

      if upper_chain.count == 17
        puts "Groups to date: " + all_upper_groups.map(&:name).join(" ")
        puts "New groups to consider: upper " + next_upper_groups.map(&:name).join(" ") + ", lower " + next_lower_groups.map(&:name).join(" ")
      end

      inter = next_upper_groups.intersection(next_lower_groups)
      if inter.count > 0
        group = inter.first # Can only be one, as upper_loc != lower_loc
        ch = [x, [upper_loc, lower_loc], group]
        if upper_chain.count >= 17 && upper_chain.count <= 22
          puts "QUUX! upper_chain has length #{upper_chain.count}."
        end
        chains << ch unless chains.map { |chain| [chain.first, chain[1].first, chain[1].last, chain.last] }.include? [x, upper_loc, lower_loc, group]
        puts "One more chain, total #{chains.count}.  Latest chain [#{ch[0]}, #{ch[1].inspect}, #{ch[2].name}].  Total length #{upper_chain.count + 1}."
        return
      else
        next_upper_groups.each do |next_upper_group|
          next_upper_locs = next_upper_group.locations(x) - Set.new([upper_loc]) # Group#location also returns a set.
          if next_upper_locs.count == 1
            next_upper_loc = next_upper_locs.first
            next_lower_groups.each do |next_lower_group|
              next_lower_locs = next_lower_group.locations(x) - Set.new([lower_loc])
              if next_lower_locs.count == 1
		puts "BAR!" if x == 6 && upper_chain.first == columns[2]
                next_lower_loc = next_lower_locs.first
                # puts "BEEP BEEP BEEP!!!" if upper_chain.last == upper_group
                # debugger if upper_chain.last == upper_group
                # OK, so it’s *next*_upper and _lower_group, obviously.
                find_chains(chains, [x, [next_upper_loc, next_lower_loc], [upper_chain << next_upper_group, lower_chain << next_lower_group]])
              else
                return
              end
            end
          else
            return
          end
        end
      end
    else # First call
      (1..9).each do |x|
        # groups.each do |group| # FIXME reinstate
        (rows + columns).each do |group|
          locs = group.locations(x)
          if locs.count == 2
	    puts "FOO!" if x == 6 && group == columns[2]
            find_chains(chains, [x, [locs.to_a.first, locs.to_a.last], [[group], [group]]])
          end
        end
      end
    end

    value = 6
    locs = [[3, 8], [8, 8]]
    group = @columns[8]
    chains = [[value, locs, group]]

    chains
  end
end

class SudokuSolver
  attr_reader :grid

  def initialize(filename = nil)
    if filename
      @grid = Grid.new(parse_file(filename))
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
          cell.cross_out(group.values(cell)) if group.include? coord
        end
      end
    end
  end

  def place
    @grid.groups.each { |group| group.place }
  end

  def nb_cell_solved
    @grid.each_value.inject(0) do |nsolved, cell|
      nsolved + if cell.solved? then 1 else 0 end
    end
  end

  def deduce
    until @grid.solved?
      old_nb_cell_solved = nb_cell_solved
      propagate
      place
      break if nb_cell_solved == old_nb_cell_solved
    end

    raise Paradox if @grid.paradox?
  end

  def guess
    @nb_hypotheses += 1
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

  # TODO Method to cross out value x from group1 when there is a group2 such that
  # group1.locations(x) is contained in group2.  Probably was there at some point.

  def parse_file(filename)
    puts "Parsing file #{filename}."
    begin
      gridfile = File.open(filename, "r")
    rescue Errno::ENOENT
      puts "Error: could not open file #{filename}."
      exit -1
    end

    def set_cell(grid, i, j, x)
      x = nil if x == "."
      grid[[i, j]] = Cell.new(x)
    end

    grid = Hash.new
    i = 0
    gridfile.each do |line| # TODO Rescue Errno::EISDIR
      if i == 9
        break
      end
      match = line.scan /\d|\./

      if match.count == 9
        9.times do |j|
          set_cell(grid, i, j, match[j])
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

  def solve(params = { })
    # Possible methods: :deduction, :guess, :tree
    method = params[:method]
    method = :deduction unless method
    begin
      deduce
      if method == :guess
        @nb_hypotheses = 0
        puts "Entering guessing mode ..."
        until @grid.solved?
          begin
	    Kernel.print "\rConsidered #{@nb_hypotheses} hypotheses so far.  Hypothesis depth: #{@hypotheses.count}."
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
    puts "  Solved!" if method == :guess and nb_cell_solved == 81
  end

  def print
    puts @grid.display
  end
end
