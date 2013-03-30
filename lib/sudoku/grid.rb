# encoding: UTF-8

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
    to_a[rand(count)]
  end
end

class Hash
  def separate
    Hash.new.tap { |rejected| delete_if { |k, v| yield(k, v) && rejected[k] = v } }
  end
end

module Sudoku
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

    def each &block
      @coords.each &block
    end

    def map &block
      @coords.map &block
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
      if params[:singles]
        1.upto(9) do |x|
          place_single(x)
        end
      end

      # Resolving cases where all the possible locations for x in group1 are included in group2
      # TODO Spec for that!
      1.upto(9).each do |x|
        locs = locations(x)
        [:row, :column, :block].each do |group_type| # TODO Group#intersecting_group_types
          areas = locs.map do |loc|
            @grid.send("#{group_type}_of", loc)
          end.uniq

          if areas.count == 1
            area = @grid.send("#{group_type}_of", locs.first)
            area.each do |coord|
              next if locs.include? coord
              @grid.cell(coord).cross_out(x)
            end
          end
        end
      end

      locs = { }
      1.upto(9).each do |x|
        locs[x] = locations(x)
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

    def place_single(x)
      locs = locations(x)
      if locs.count == 1
        loc = locs.first
        @grid.cell(loc).set_solved(x)
        # Propagate to all the groups containing loc.
        groups = @grid.groups_of(loc)
        groups.each do |group|
          group.each do |coord|
            @grid.cell(coord).cross_out(x) unless coord == loc
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

    def name
      first_coord = @coords.first
      k = 3 * (first_coord.first / 3) + first_coord.last / 3
      "Block #{k}"
    end
  end

  class Grid
    attr_reader :rows, :columns, :blocks

    def initialize(grid = nil, solver = nil) # FIXME horrible.  Solver should never be nil anyway.
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

      @solver = solver

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

        all_upper_groups = upper_chain.to_set
        all_lower_groups = lower_chain.to_set

        next_upper_groups = groups_of(upper_loc) - all_upper_groups # groups_of returns a set.
        next_lower_groups = groups_of(lower_loc) - all_lower_groups

        inter = next_upper_groups.intersection(next_lower_groups)
        if inter.count > 0
          group = inter.first # Can only be one, as upper_loc != lower_loc
          ch = [x, [upper_loc, lower_loc], group]
          chains << ch unless chains.map { |chain| [chain.first, chain[1].first, chain[1].last, chain.last] }.include? [x, upper_loc, lower_loc, group]
          @solver.output.puts "One more chain, total #{chains.count}.  Latest chain [#{ch[0]}, #{ch[1].inspect}, #{ch[2].name}].  Total length #{upper_chain.count + 1}." if @solver.verbose?
          return
        else
          next_upper_groups.each do |next_upper_group|
            next_upper_locs = next_upper_group.locations(x) - Set.new([upper_loc]) # Group#location also returns a set.
            if next_upper_locs.count == 1
              next_upper_loc = next_upper_locs.first
              next_lower_groups.each do |next_lower_group|
                next_lower_locs = next_lower_group.locations(x) - Set.new([lower_loc])
                if next_lower_locs.count == 1
                  next_lower_loc = next_lower_locs.first
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
          groups.each do |group|
            locs = group.locations(x)
            # FIXME Test shouldn’t be needed
            # if locs.count == 2
              find_chains(chains, [x, [locs.to_a.first, locs.to_a.last], [[group], [group]]])
            # end
          end
        end
      end

      chains
    end
  end
end
