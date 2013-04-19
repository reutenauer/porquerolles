# encoding: UTF-8
require 'spec_helper'

describe Set do
  describe "#subsets" do
    it "returns the set of all subsets" do
      set = Set.new(1..3)
      subsets = set.subsets
      subsets.should have(8).elements
      subsets.should include Set.new([1])
      subsets.should include Set.new(2..3)
      subsets.should include set
    end
  end

  describe "#random" do
    it "returns a random element" do
      set = Set.new(0..9)
      r = set.random
      set.should include r
    end
  end
end

describe Hash do
  describe "#separate" do
    it "splits the hash according to a criterion specified as a block" do
      hash = Hash.new.tap do |h|
        (1..12).each do |n|
          x = (96 + n).chr.to_sym
          h[x] = 12 - n # h = { :a => 11, :b => 10, ... , :l => 0 }
        end
      end

      lower = hash.separate { |k, v| v < 6 }
      lower.should have(6).elements
      hash.should have(6).elements
      lower.all? { |k, v| v.should < 6 }
    end
  end

  describe "#dclone" do
   it "return a deeps copy of itself, with standard objects" do
     h = { :a => 1, :b => "foo", :c => { :d => 3, :e => 4, :f => 5 } }
     h2 = h.dclone
     h2.should have(h.count).elements
     h.should == h2
     h.should_not be_equal h2
     h[:c].should == h2[:c]
     h[:c].should_not be_equal h2[:c]
   end

    it "returns a deep copy of itself, with cells" do
      h = { :a => Sudoku::Cell.new, :b => Sudoku::Cell.new(2), :c => Sudoku::Cell.new(3) }
      h2 = h.dclone
      h.should == h2
      h2.should have(h.count).elements
      h.should_not be_equal h2
      [:a, :b, :c].each do |key|
        h[key].should == h2[key]
        h[key].should_not be_equal h2[key]
      end
    end
  end
end

module Sudoku
  describe Cell do
    describe ".new" do
      it "creates a cell with all possible values by default" do
        cell = Cell.new
        cell.should have(9).possible_values
      end

      it "creates a solved cell when given a numeric argument" do
        cell = Cell.new(2)
        cell.should be_solved
      end
    end

    describe "#value" do
      it "returns the cell’s value when solved" do
        cell = Cell.new(3)
        cell.value.should == 3
      end

      it "raises when not soveld" do
        cell = Cell.new
        expect { cell.value }.to raise_error
      end
    end

    describe "#cross_out" do
      it "crosses out possible values" do
        cell = Cell.new
        expect { (1..3).each { |x| cell.cross_out(x) } }.to change(cell, :count).by(-3)
      end

      it "... even if there would none left" do
        cell = Cell.new(6)
        cell.cross_out(6)
        cell.should have(0).possible_values
      end
    end

    describe "#set_solved" do
      it "sets a cell’s value" do
        cell = Cell.new
        cell.set_solved(7)
        cell.should be_solved
        cell.value.should == 7
      end
    end

    describe "#include?" do
      it "says whether a cell includes a value" do
        cell = Cell.new
        cell.should include 8
        cell.cross_out(8)
        cell.should_not include 8
      end
    end

    describe "#solved?" do
      it "says whether a cell is solved" do
        cell = Cell.new
        cell.solved?.should be_false
      end

      it "says whether a cell is solved" do
        cell = Cell.new(9)
        cell.solved?.should be_true
      end
    end

    describe "#display" do
      it "returns '.' a graphical representation of an unsolved cell" do
        cell = Cell.new
        cell.display.should == "."
      end

      it "returns 'x' as graphical representation of a cell with value x" do
        cell = Cell.new(6)
        cell.display.should == "6"
      end
    end

    describe "#dup" do
      it "returns a copy of the cell" do
        cell1 = Cell.new
        cell1.cross_out([6, 7, 8])
        cell2 = cell1.dup
        cell2.should_not be_equal cell1
        cell2.should have(6).possible_values
      end
    end

    describe "#guess" do
      it "chooses a value from the possible values, and marks the cell as solved with that value" do
        cell = Cell.new
        bad_values = [1, 2, 3, 7, 8, 9]
        good_values = (1..9).to_a - bad_values
        cell.cross_out(bad_values)
        cell.guess
        good_values.should include cell.value
      end
    end

    describe "#deadlock?" do
      it "returns true if cell has no value" do
        cell = Cell.new(5)
        cell.cross_out(5)
        cell.deadlock?.should be_true
      end

      it "returns false otherwise" do
        cell = Cell.new(6)
        cell.deadlock?.should be_false
      end
    end

    describe "#each" do
      it "returns an enumerator" do
        cell = Cell.new
        cell.each.should be_an Enumerator
      end

      it "loops over all the possible values" do
        cell = Cell.new
        cell.each.should have(9).issues
        cell.each.to_a.should =~ (1..9).to_a
      end
    end

    describe "==" do
      it "tests for equality" do
        c1a = Cell.new
        c1b = Cell.new
        c1a.should == c1a

        c2a = Cell.new(3)
        c2b = Cell.new(3)
        c2c = Cell.new(4)
        c2a.should == c2b
        c2a.should_not == c2c

        c3a = Cell.new
        c3b = Cell.new
        c3c = Cell.new
        c3a.cross_out([2, 3, 5, 7])
        c3b.cross_out([2, 3, 5, 7])
        c3c.cross_out([2, 4, 6, 8])
        c3a.should == c3b
        c3a.should_not == c3c
      end
    end
  end

  describe Group do
    let(:grid) { Grid.new }
    let(:group) { grid.rows.first }

    context "with some heavily stubbed data" do
      before(:each) do
        @cell1 = group.cells[0]
        @cell2 = group.cells[1]
        @cell3 = group.cells[2]
        @cell1.stub(:values).and_return(Set.new(1..2))
        @cell2.stub(:values).and_return(Set.new(1..2))
      end

      describe "#possible_values" do
        it "collects possible values" do
          group.possible_values(Set.new([@cell1, @cell2])).should == Set.new(1..2)
        end
      end

      describe "#resolve_location_subsets" do
        it "resolves location subsets" do
          @cell3.should_receive(:cross_out).with(Set.new(1..2))

          group.resolve_location_subsets
        end
      end
    end

    describe "#locations" do
      it "is not memoized" do
        (0..1).each do |i|
          group.cells[i].should_receive(:include?).with(1).once.and_return(true) # would be once with mem.
        end

        (2..8).each do |i|
          group.cells[i].should_receive(:include?).with(1).once.and_return(false)
        end

        group.locations(1).should == Set.new([[0, 0], [0, 1]])
        group.locations(1)
      end
    end
  end

  describe Row do
    let(:grid) { Grid.new }

    describe "#name" do
      it "returns its own name" do
        grid.rows[2].name.should == "Row 2"
      end
    end
  end

  describe Column do
    let(:grid) { Grid.new }

    describe "#name" do
      it "returns its own name" do
        grid.columns[6].name.should == "Column 6"
      end
    end
  end

  describe Block do
    let(:grid) { Grid.new }

    describe "#name" do
      it "returns its own name" do
        grid.blocks[8].name.should == "Block 8"
        grid.blocks[4].name.should == "Block 4"
        grid.blocks[2].name.should == "Block 2"
      end
    end

    describe '#place_single' do
      it "works" do
        grid = Grid.new
        grid.ingest(read_grid_file('guardian/2423.sdk'))
        block = grid.blocks.first

        (1..9).each do |x|
          block.place_single(x)
        end
      end

      it "places one value on one single values" do
        grid = Grid.new
        grid.ingest(read_grid_file('simple.sdk'))
        grid = grid
        cell = grid[6, 7]
        block = grid.blocks.last

        grid.propagate
        cell.should_not be_solved
        cell.should have(3).elements

        block.place_single(1)
        cell.should be_solved
        cell.value.should == 1
      end
    end
  end


  describe Grid do
    let(:output) { double("output").as_null_object }
    let(:grid) { Grid.new(output) }

    describe "#new" do
      it "instantiates a new grid, outputting to /dev/null" do
        Grid.new
      end

      it "instantiates a new grid, writing to some output" do
        Grid.new(output)
      end
    end

    describe "#set_solved" do
      it "marks a cell as solved" do
        grid.ingest(read_grid_file('simple.sdk'))
        expect { grid.set_solved([6, 7], 1) }.to change(grid, :count).by(1)
      end

      it "raises an error if differs from reference" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.setup(:references => true)
        expect { grid.set_solved([6, 7], 2) }.to raise_error(DiffersFromReference)
      end
    end

    describe "#cross_out" do
      it "works roughly the same way as #set_solved" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.propagate
        expect { grid.cross_out([6, 7], Set.new([6, 8])) }.to change(grid, :count).by(1)
      end

      it "raises an error if differs from reference" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.setup(:references => true)
        grid.propagate
        expect { grid.cross_out([6, 7], Set.new([1, 8])) }.to raise_error(DiffersFromReference)
      end
    end

    describe "#data?" do
      it "refuses to do something useless" do
        grid
        grid.data?.should be_false
      end

      it "refuses to do something even more useless" do
        expect { grid.ingest(nil) }.to raise_error(NoGridInput) # Would create a trivial matrix before
      end
    end

    describe "#set_solved" do
      it "delegates to Cell" do
        cell = grid[1, 1]
        cell.should_receive(:set_solved).with(1) # Very weak test, but OK ...
        grid.set_solved([1, 1], 1)
      end
    end

    describe "#cross_out" do
      it "crosses out as not a possible value" do
        cell = Cell.new
        cell.should have(9).possible_values
        cell.cross_out(1)
        cell.should have(8).possible_values
        (2..8).each { |x| cell.cross_out(x) }
        cell.should be_solved
        cell.value.should == 9
      end

      it "delegates to Cell" do
        cell = grid[8, 8]
        cell.should_receive(:cross_out).with(8)
        grid.cross_out([8, 8], 8)
      end
    end

    describe "#min" do
      it "is memoized" do
        grid = Grid.new
        grid.each_value do |cell|
          cell.should_receive(:count).and_return(2)
        end

        grid.min.should == 2
        grid.min # Second call should not call cell.count a second time
      end
    end

    context "with an empty grid" do
      let(:grid) { Grid.new }

      describe "#coord" do
        it "returns the coordinates of a cell" do
          cell = grid[2, 3]
          grid.coord(cell).should == [2, 3]
        end
      end

      describe "#row_of" do
        it "finds the row of one cell" do
          grid.row_of([2, 3]).should == grid.rows[2]
        end
      end

      describe "#column_of" do
        it "finds the column on one cell" do
          grid.column_of([4, 6]).should == grid.columns[6]
        end
      end

      describe "#block_of" do
        it "finds the block of some cells" do
          grid.block_of([6, 6]).should == grid.blocks[8]
          grid.block_of([4, 3]).should == grid.blocks[4]
          grid.block_of([4, 4]).should == grid.blocks[4]
          grid.block_of([2, 8]).should == grid.blocks[2]
        end
      end

      describe "#groups_of" do
        it "finds the groups to which one cell belongs" do
          # TODO Write matcher for that
          grid.groups_of([4, 6]).class.should == Set
          grid.groups_of([4, 6]).to_a.should =~ [grid.rows[4], grid.columns[6], grid.blocks[5]]
        end
      end
    end

    describe "#find_chains", :slow => true do
      let(:grid) { Grid.new }

      it "finds a link", :slow => true do
        grid.ingest(read_grid_file('misc/X-wing.sdk'))
        grid.solve
        # TODO Write a matcher for that too
        grid.find_chains.include?([6, [[3, 8], [8, 8]], grid.columns[8]]).should == true
      end

      it "does not crash" do
        grid.ingest(read_grid_file('guardian/2423.sdk'))
        grid.solve(:chains => true)
      end

      it "does still not crash" do
        grid.ingest(read_grid_file('misc/X-wing-3.sdk'))
        grid.solve(:chains => true)
      end

      it "does not crash, even on the third attempt" do
        grid.ingest(read_grid_file('misc/X-wing-4.sdk'))
        grid.solve(:chains => true)
      end

      it "does not crash?" do
        pending "Actually it does crash" do
          grid.ingest(read_grid_file('guardian/2094.sdk'))
          grid.solve(:chains => true)
        end
      end

      it "does not returns chains for groups when group.locations(x).count = 1!" do
        pending "Test hard to write"
      end

      it "does not return chains when the upper_group = lower_group" do
        pending "Test hard to write too"
      end

      it "tests for something else too"
    end

    describe "#resolve_chains" do
      it "uses that links returned by #find_chains" do
        grid.ingest(read_grid_file('misc/X-wing.sdk'))
        # grid.solve(:chains => true)
        grid.deduce
        grid.rows.first.resolve_location_subsets
        # grid[0, 8].should_receive(:cross_out).with(6)
        grid.resolve_chains
        grid[0, 8].should be_solved
        grid[0, 8].value.should == 8
      end
    end

    describe "#parse_options" do
      it "passes the verbose option" do
        grid.parse_options(['-v'])
        grid.should be_verbose
      end

      it "passes the quiet option, as “non-verbose”" do
        grid.parse_options(['-q'])
        grid.should_not be_verbose
      end

      it "passes the quiet option, overriding verbose" do
        grid.parse_options(['-v', '-q'])
        grid.should_not be_verbose
      end

      it "passes two options using the compact syntax" do
        grid.parse_options(['-vc'])
        grid.should be_verbose
        grid.should be_chained
      end

      it "passes the “references” options" do
        grid.parse_options(['-r'])
        grid.ingest(read_grid_file('simple.sdk'))
        grid.should be_referenced
      end

      it "passes the “well-formed” options" do
        grid.parse_options(['-w'])
        grid.should be_validating
      end

      it "passes the “inline” option" do
        grid.parse_options(['-i'])
        grid.should be_inlined
      end

      it "outputs a message when it encounters an unknown options" do
        output.should_receive(:puts).with("Error: invalid option: -f")
        grid.parse_options(['-f'])
      end

      it "outputs extra messages when verbose" do
        output.should_receive(:puts).with("One more chain, total 16.  Latest chain [6, [[3, 8], [8, 8]], Column 8].  Total length 3.")
        grid.ingest(read_grid_file('misc/X-wing.sdk'))
        grid.solve(:verbose => true, :chains => true)
      end

      it "solves using the chains option" do
        grid.ingest(read_grid_file('misc/X-wing.sdk'))
        grid.solve(:chains => true)
        grid.should be_solved
      end
    end

    describe "#ingest" do
      it "ingests a grid from a file" do
        grid.ingest(read_grid_file('guardian/2084.sdk'))
        grid.should have(27).solved_cells
      end

      it "ingests a grid from a matrix" do
        grid.ingest(read_grid_file('guardian/2084.sdk'))

        grid2 = Grid.new
        grid2.ingest(grid.matrix)
        grid.should have(27).solved_cells
        grid2.should have(27).solved_cells
      end

      it "ingests a grid from an inline string" do
        grid.ingest("600100002002096100000004095000700800060000030007005000830400000006520900200001003", :inline => true)
        grid.should be_valid
        grid.should have(26).solved_cells
      end
    end

    describe "#method" do
      it "returns :deduction by default" do
        grid.method.should == :deduction
      end

      it "sets it to something on demand" do
        grid.stub(:solved?).and_return(:true) # So that we’ll return immediately after the deduce phase
        grid.setup(:method => :guess)
        grid.method.should == :guess
      end
    end

    describe "#validating?" do
      it "only checks for validity if @params[:validating] is set" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.setup(:validating => true)
        grid.solve
        grid.should_not be_solved
      end

      it "returns true for a valid grid" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.setup(:validating => true)
        output.should_receive(:puts).with("Grid is valid.")
        grid.solve
      end

      context "with some unnecessarily long string" do
        let(:ascii_art) { "+---+---+---+\n|8.6|.7.|45.|\n|7..|..4|693|\n|..4|...|8.7|\n+---+---+---+\n|..1|8.7|2.6|\n|.6.|4.2|.7.|\n|2.7|3.6|1..|\n+---+---+---+\n|4.3|...|9..|\n|612|5..|..4|\n|.58|.4.|3.2|\n+---+---+---+\n" }

        it "does print the ASCII-art grid for a normal run." do
          grid.setup(:validating => false)
          output.should_receive(:puts).with(ascii_art)
          grid.run([read_grid_file('simple.sdk')])
        end

        it "does not print the ASCII-art grid for a validating run" do
          grid.ingest(read_grid_file('simple.sdk'))
          grid.setup(:validating => true)
          output.should_not_receive(:puts).with(ascii_art)
          grid.solve
        end
      end
    end

    describe '#parse_file' do
      let(:grid_dir) { File.expand_path('../../../grids', __FILE__) }
      let(:gridfile) { File.join(grid_dir, 'guardian/2084.sdk') }

      it "parses the file" do
        grid.parse_file(gridfile)
        # TODO Test that the grid is correctly input
      end

      it "outputs a message" do
        output.should_receive(:puts).with("Parsing file #{gridfile}.")
        grid.parse_file(gridfile)
      end

      it "stores the file name somewhere" do
        grid.ingest(gridfile)
        grid.filename.should == gridfile
      end

      it "stores the original grid somewhere" do
        grid.ingest(gridfile)
        # TODO Matcher for that, as usual
        grid.original_grid.class.should == Hash
        grid.original_grid.all? { |k, v| v == grid.cell(k) }
      end
    end

    describe "#parse_inline" do
      it "parses a string describing the sudoku, with 0 and values from 1 to 9" do
        grid = Grid.new
        grid.parse_inline("058006000300000500740953000000300060470090021090008000000219078002000005000500210")
        grid.should be_valid
        grid.count.should == 29
      end
    end

    describe "#guess" do
      it "solves with the :guess method" do
        grid = Grid.new
        grid.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        grid.solve(:method => :guess)
        grid.should be_solved
      end
    end

    describe "count" do
      before(:all) do
        @grid = Grid.new
      end

      it "returns 0 on a fresh grid" do
        @grid.count.should == 0
      end

      it "returns n after marking n cells as solved" do
        (1..8).each { |x| @grid[x, x].set_solved(x) }
        @grid.count.should == 8
      end

      it "returns 81 after fully solving the grid" do
        @grid.each_value { |cell| cell.set_solved(3) }
        @grid.count.should == 81
      end
    end

    describe "#grand_count" do
      before(:all) do
        @grid = Grid.new
      end

      it "adds number of all possible values in each cells" do
        @grid.grand_count.should == 729
      end

      it "crosses out a few values from a few cells" do
        expect do
          (0..2).each { |x| @grid[x, x].cross_out(Set.new(3..5)) }
        end.to change(@grid, :grand_count).by(-9) # should now be 720
      end

      it "set a few cells as solved" do
        (6..8).each { |x| @grid[x, 8 - x].set_solved(x) } # reduces further by 3 × 8
        @grid.grand_count.should == 696
      end

      it "returns 81 on a solved real grid" do
        @grid.ingest(read_grid_file('simple.sdk'))
        @grid.solve
        @grid.grand_count.should == 81
      end
    end

    describe "#setup" do
      it "sets some options" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.should_not be_referenced
        grid.setup(:references => true)
        grid.should be_referenced
      end
    end

    describe "#solve" do
      it "sets additional options" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.should_not be_verbose
        grid.solve(:verbose => true)
        grid.should be_verbose
      end

      it "solves an easy grid" do
        grid.ingest(read_grid_file('guardian/2423.sdk'))
        # Not sure whether to test that.
        # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
        grid.solve
        grid.should be_solved
      end

      it "calls reference if called with references" do # OK, that’s a little cryptic ...
       pending "Renegociation of responsibilities" do
         grid.ingest(read_grid_file('simple.sdk'))
         grid.should_receive(:reference)
         grid.solve(:references => true)
        end
      end

      it "is not trivial" do
        grid.ingest(read_grid_file('simple.sdk'))
        grid.solve
        grid.reference.should be_equal grid
      end
    end

    describe "#reference" do
      it "computes a reference solution grid", :slow => true do
        grid.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        grid.reference.should act_as_a_solved_grid
      end

      it "catches some nasty inconsistencies" do
        grid.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        grid.stub_chain(:reference, :cell, :value).and_return(3)
        expect { grid.solve(:references => true, :chains => true) }.to raise_error(DiffersFromReference)
      end
    end

    describe "#run" do
    let(:griddir) { File.expand_path('../../../grids', __FILE__) }

      it "runs a simple file" do
        grid.run([File.join(griddir, 'simple.sdk')])
      end

      it "ingests an inline description of the grid if run with -i" do
        grid.run(['-i', "600100002002096100000004095000700800060000030007005000830400000006520900200001003"])
        pending "renegociation of responsibilities"
        # Grid should be input from the string directly, by-passing parse_file etc.
      end
    end

    describe "#deadlock?", :slow => true do
      it "never uses deadlock?" do
        grid.should_not_receive(:deadlock?)
        grid.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        grid.solve(:verbose => true, :method => :guess, :chains => true)
      end
    end

    describe "#safe_solve" do
      it "never raises" do
        grid.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        grid.safe_solve
        grid.should_not be_solved
      end
    end
  end
end
