# encoding: UTF-8
# Some lines may have up to 108 characters (more comfortable than 72 or 80).

require 'rubygems'
require 'set'
require 'debugger'
require 'optparse'

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

  def copy
    Set.new(to_a.slice(0, count))
  end
end

class Hash
  def separate
    Hash.new.tap { |rejected| delete_if { |k, v| yield(k, v) && rejected[k] = v } }
  end
end

# TODO exit -1 when applicable.
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
    attr_writer :values

    def initialize(x = nil)
      if x
        @values = Set.new([x.to_i])
      else
        @values = Set.new(1..9)
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
      Cell.new.tap { |cell| cell.values = @values.copy }
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
        (1..9).each do |x|
          place_single(x)
        end
      end

      # Resolving cases where all the possible locations for x in group1 are included in group2
      # TODO Spec for that!
      (1..9).each do |x|
        locs = locations(x)
        [:row, :column, :block].each do |group_type| # TODO Group#intersecting_group_types
          areas = locs.map do |loc|
            @grid.send("#{group_type}_of", loc)
          end.uniq

          if areas.count == 1
            area = @grid.send("#{group_type}_of", locs.first)
            area.each do |coord|
              next if locs.include? coord
              @grid.cross_out(coord, x)
            end
          end
        end
      end

      locs = { }
      (1..9).each do |x|
        locs[x] = locations(x)
        raise Deadlock if locs[x].count == 0
      end
      unsolved = locs.separate { |x, l| l.count > 1 }

      locs.each do |x, l|
        @grid.set_solved(l.first, x)
      end

      unsolved_values = unsolved.each_key.to_set
      subsets = unsolved_values.subsets
      subsets.each do |subset|
        these_locs = subset.inject(Set.new) { |l, x| l + unsolved[x] }
        if these_locs.count == subset.count
          values_to_cross_out = unsolved_values - subset
          these_locs.each do |coord|
            @grid.cross_out(coord, values_to_cross_out)
          end
        end
      end
    end

    def place_single(x)
      locs = locations(x)
      if locs.count == 1
        loc = locs.first
        @grid.set_solved(loc, x)
        # Propagate to all the groups containing loc.
        groups = @grid.groups_of(loc)
        groups.each do |group|
          group.each do |coord|
            @grid.cross_out(coord, x) unless coord == loc
          end
        end
      end
    end

    def paradox?
      (1..9).any? do |x|
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
    attr_reader :matrix, :rows, :columns, :blocks, :filename, :original_grid

    # The new initialize for the merger of Grid and Solver
    def initialize(output = NullOutput.new, matrix = nil) # Merging both signatures.
      # From Solver
      @output = output
      @hypotheses = []
      @node = Tree.new
      @params = { }

      # From Grid
      if matrix # was: grid
        @matrix = matrix
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

    def set_solved(coord, value)
      raise DiffersFromReference if referenced? && reference.cell(coord) != value
      cell(coord).set_solved(value)
    end

    def cross_out(coord, values)
      c = cell(coord)
      c.cross_out(values)
      raise DiffersFromReference if referenced? && c.solved? && reference.cell(coord) != c.value
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
     Grid.new(@output,
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
        matrix = copy
        matrix[coord].set_solved(val)
        hypothesis = Hypothesis.new(matrix, coord, val)
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
          @output.puts "One more chain, total #{chains.count}.  Latest chain [#{ch[0]}, #{ch[1].inspect}, #{ch[2].name}].  Total length #{upper_chain.count + 1}." if verbose?
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

    def parse_options(args)
      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] <file name>"

        opts.on('-s', "--[no]-singles", "Place single candidates") do |s|
          @params[:singles] = s
        end

        opts.on('-d', "--deduction", "Use deduction method") do
          @params[:method] = :deduction
        end

        opts.on('-c', "--[no-]chains", "Find chains") do |c|
          @params[:chains] = c
        end

        opts.on('-g', "--guess", "Use guess method") do
          @params[:method] = :guess
        end

        opts.on('-v', "--[no-]verbose", "Be more verbose") do |v|
          @params[:verbose] = v
        end

        opts.on('-q', "--[no-]quiet", "Be quieter") do |q|
          # Note: if we only use the key :verbose, the defaults are correct (i. e., quiet).
          @params[:verbose] = !q
        end

        opts.on('-r', "--[no-]references", "References to full solution") do |r|
          @params[:references] = r
        end

        # No tree yet.

        begin
          opts.parse!(args)
        rescue OptionParser::InvalidOption => message
          @output.puts "Error: #{message}"
          @output.puts opts
        end
      end
    end

    def ingest(input)
      if input.is_a? String
        @filename = input
        parse_file(input)
      elsif input.is_a? Hash
        @matrix = Hash.new.tap do |hash|
          input.each do |coord, cell|
            hash[coord] = cell.copy
          end
        end
      end

      @original_grid = Hash.new.tap do |hash|
        @matrix.each do |coord, cell|
          hash[coord] = cell.copy
        end
      end
    end

    def verbose?
      @params[:verbose] if @params
    end

    def chained?
      @params[:chains] if @params
    end

    def referenced?
      @params[:references]
    end

    def propagate
      each do |coord, cell|
        unless cell.solved?
          groups.each do |group|
            cell.cross_out(group.values(cell)) if group.include? coord
          end
        end
      end
    end

    def place
      groups.each { |group| group.place(@params) }
    end

    def find_chains_solver
      find_chains.each do |chain|
        x = chain[0]
        upper_loc = chain[1].first
        lower_loc = chain[1].last
        group = chain[2]
        group.each do |coord|
          next if coord == upper_loc || coord == lower_loc
          cell(coord).cross_out(x)
        end
      end
    end

    def nb_cell_solved
      each_value.inject(0) do |nsolved, cell|
        nsolved + if cell.solved? then 1 else 0 end
      end
    end

    def count
      nb_cell_solved
    end

    def deduce
      until solved?
        old_nb_cell_solved = nb_cell_solved
        propagate
        place
        find_chains_solver if chained?
        break if nb_cell_solved == old_nb_cell_solved
      end

      raise Paradox if paradox?
    end

    def guess
      @nb_hypotheses += 1 # FIXME That’s ridiculous.  Use @hypotheses.count
      last_hyp_grid = if @hypotheses.count > 0 then @hypotheses.last.grid else self end
      grid = last_hyp_grid.copy
      coord_and_cell = grid.random
      coord = coord_and_cell.first
      cell = coord_and_cell.last
      val = cell.guess
      @hypotheses << Hypothesis.new(grid, coord, val)
    end

    # TODO Method to cross out value x from group1 when there is a group2 such that
    # group1.locations(x) is contained in group2.  Probably was there at some point.

    def parse_file(filename)
      @output.puts "Parsing file #{filename}."
      begin
        gridfile = File.open(filename, "r")
      rescue Errno::ENOENT
        @output.puts "Error: could not open file #{filename}."
        exit -1
      end

      # TODO Refactor that
      def self.set_cell(matrix, i, j, x)
        x = nil if x == "."
        matrix[[i, j]] = Cell.new(x)
      end

      matrix = Hash.new
      i = 0
      gridfile.each do |line| # TODO Rescue Errno::EISDIR
        if i == 9
          break
        end
        match = line.scan /\d|\./

        if match.count == 9
          9.times do |j|
            set_cell(@matrix, i, j, match[j])
          end

          i = i + 1
        end
      end

      if i != 9
        @output.puts "Error: could not input grid from file #{filename}."
      end
    end

    def backtrack
      hypothesis = @hypotheses.pop
      if hypothesis then grid = hypothesis.grid else grid = self end
      backtrack if grid.paradox?
    end

    def valid?
      !paradox?
    end

    def method
      @params[:method] || :deduction
    end

    def setup(params = nil)
      @params.merge!(params) if params
    end

    def data?
      @original_grid
    end

    def solve(params = nil)
      raise NoGridInput unless data?

      @params.merge!(params) if params
      reference if referenced?
      # Possible methods: :deduction, :guess, :tree
      begin
        deduce
        if method == :guess && !solved?
          grid = self
          @nb_hypotheses = 0
          @output.puts "Entering guessing mode ..."
          until grid.solved?
            begin
	      @output.print "\rConsidered #{@nb_hypotheses} hypotheses so far.  Hypothesis depth: #{@hypotheses.count}."
              guess
              grid = @hypotheses.last.grid
              grid.deduce
              if grid.deadlock?
                puts "Deadlock (1), backtracking ..."
                backtrack
              end
            rescue Deadlock
              backtrack
            end
          end

          @output.puts "  Solved!" if method == :guess and grid.nb_cell_solved == 81
          @matrix = Hash.new.tap { |m| grid.each { |cr, cl| m[cr] = cl } }
        elsif method == :tree
          tree.each do |node|
            node.grid.tree
          end
	  # TODO...
        end
      rescue Paradox
        @output.puts "Sudoku insoluble."
      end
    end

    def print
      @output.puts display
    end

    def reference
      if @reference
        @reference
      elsif solved?
        @reference = self
      else
        pre_solver = Grid.new
        pre_solver.ingest(@original_grid)
        pre_solver.solve(:method => :guess)
        @reference = pre_solver
      end
    end

    def run(args)
      parse_options(args)

      args.each do |arg|
        ingest(arg)
        print
        unless valid?
          puts "Grid is not valid.  Exiting."
          exit
        end
        solve
        print
      end
    end

    def safe_solve(params = nil, debug = false)
      begin
        solve(params)
      rescue DiffersFromReference
        debugger if debug
      end
    end
  end
end
