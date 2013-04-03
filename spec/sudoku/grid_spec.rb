# encoding: UTF-8
require 'spec_helper'

describe Set do
  describe "#copy" do
    it "returns a copy of self" do
      set = Set.new([1, 2, 3])
      set2 = set.copy
      set2.should_not be_equal set
      set2.should == set
    end
  end
end

module Sudoku
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
  end

  describe Block do
    let(:solver) { Grid.new }

    describe "#set_solved" do
      it "marks a cell as solved" do
        solver.ingest(read_grid_file('simple.sdk'))
        expect { solver.set_solved([6, 7], 1) }.to change(solver, :count).by(1)
      end

      it "raises an error if differs from reference" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.setup(:references => true)
        expect { solver.set_solved([6, 7], 2) }.to raise_error(DiffersFromReference)
      end
    end

    describe "#cross_out" do
      it "works roughly the same way as #set_solved" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.propagate
        expect { solver.cross_out([6, 7], Set.new([6, 8])) }.to change(solver, :count).by(1)
      end

      it "raises an error if differs from reference" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.setup(:references => true)
        solver.propagate
        expect { solver.cross_out([6, 7], Set.new([1, 8])) }.to raise_error(DiffersFromReference)
      end
    end

    describe "#data?" do
      it "refuses to do something useless" do
        solver.stub(:data?).and_return(false)
        solver.should_receive(:raise).with(NoGridInput)
        solver.solve
      end

      it "refuses to do something even more useless" do
        expect { solver.ingest(nil) }.to raise_error(NoGridInput) # Would create a trivial matrix before
      end
    end

    describe "#set_solved" do
      it "delegates to Cell" do
        cell = solver[1, 1]
        cell.should_receive(:set_solved).with(1) # Very weak test, but OK ...
        solver.set_solved([1, 1], 1)
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
        cell = solver[8, 8]
        cell.should_receive(:cross_out).with(8)
        solver.cross_out([8, 8], 8)
      end
    end

    describe '#place_single' do
      it "works" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        block = solver.blocks.first

        (1..9).each do |x|
          block.place_single(x)
        end
      end

      it "places one value on one single values" do
        solver = Grid.new
        solver.ingest(read_grid_file('simple.sdk'))
        grid = solver
        cell = grid[6, 7]
        block = grid.blocks.last

        solver.propagate
        cell.should_not be_solved
        cell.should have(3).elements

        block.place_single(1)
        cell.should be_solved
        cell.value.should == 1
      end
    end

    describe "#min" do
      it "is memoized"
    end
  end

  describe Group do
    describe "#locations" do
      it "is memoized"
    end
  end

  describe "Convenience methods" do
    context "with an empty grid" do
      let(:grid) { Grid.new }

      describe "Row#name" do
        it "works" do
          grid.rows[2].name.should == "Row 2"
        end
      end

      describe "Column#name" do
        it "works" do
          grid.columns[6].name.should == "Column 6"
        end
      end

      describe "Block#name" do
        it "works" do
          grid.blocks[8].name.should == "Block 8"
          grid.blocks[4].name.should == "Block 4"
          grid.blocks[2].name.should == "Block 2"
        end
      end
    end
  end

  describe Grid do
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

    describe "#find_chains" do
      let(:solver) { Grid.new }
      let(:grid) { solver }

      it "finds a link" do
        solver.ingest(read_grid_file('misc/X-wing.sdk'))
        solver.solve
        # TODO Write a matcher for that too
        grid.find_chains.include?([6, [[3, 8], [8, 8]], grid.columns[8]]).should == true
      end

      it "uses that link" do
        solver.ingest(read_grid_file('misc/X-wing.sdk'))
        # solver.solve(:chains => true)
        solver.deduce
        solver.rows.first.resolve_location_subsets
        # solver[0, 8].should_receive(:cross_out).with(6)
        solver.find_chains_solver
        solver[0, 8].should be_solved
        solver[0, 8].value.should == 8
      end

      it "does not crash" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        solver.solve(:chains => true)
      end

      it "does still not crash" do
        solver.ingest(read_grid_file('misc/X-wing-3.sdk'))
        solver.solve(:chains => true)
      end

      it "does not crash, even on the third attempt" do
        solver.ingest(read_grid_file('misc/X-wing-4.sdk'))
        solver.solve(:chains => true)
      end

      it "does not returns chains for groups when group.locations(x).count = 1!" do
        pending "Test hard to write"
      end

      it "does not return chains when the upper_group = lower_group" do
        pending "Test hard to write too"
      end

      it "tests for something else too"
    end
  end

  describe "Old Solver" do
    let(:output) { double("output").as_null_object }
    let(:solver) { Grid.new(output) }

    describe "#new" do
      it "instantiates a new solver, outputting to /dev/null" do
        Grid.new
      end

      it "instantiates a new solver, writing to some output" do
        Grid.new(output)
      end
    end

    describe "#parse_options" do
      it "passes the verbose option" do
        solver.parse_options(['-v'])
        solver.should be_verbose
      end

      it "passes the quiet option, as “non-verbose”" do
        solver.parse_options(['-q'])
        solver.should_not be_verbose
      end

      it "passes the quiet option, overriding verbose" do
        solver.parse_options(['-v', '-q'])
        solver.should_not be_verbose
      end

      it "passes two options using the compact syntax" do
        solver.parse_options(['-vc'])
        solver.should be_verbose
        solver.should be_chained
      end

      it "passes the “references” options" do
        solver.parse_options(['-r'])
        solver.ingest(read_grid_file('simple.sdk'))
        solver.should be_referenced
      end

      it "passes the “well-formed” options" do
        solver.parse_options(['-w'])
        solver.should be_validating
      end

      it "outputs a message when it encounters an unknown options" do
        output.should_receive(:puts).with("Error: invalid option: -f")
        solver.parse_options(['-f'])
      end

      it "outputs extra messages when verbose" do
        output.should_receive(:puts).with("One more chain, total 17.  Latest chain [6, [[3, 8], [8, 8]], Column 8].  Total length 3.")
        solver.ingest(read_grid_file('misc/X-wing.sdk'))
        solver.solve(:verbose => true, :chains => true)
      end

      it "solves using the chains option" do
        solver.ingest(read_grid_file('misc/X-wing.sdk'))
        solver.solve(:chains => true)
        solver.should be_solved
      end
    end

    describe "#ingest" do
      it "ingests a grid from a file" do
        solver.ingest(read_grid_file('guardian/2084.sdk'))
        solver.should have(27).solved_cells
      end

      it "ingests a grid from a matrix" do
        solver.ingest(read_grid_file('guardian/2084.sdk'))

        solver2 = Grid.new
        solver2.ingest(solver.matrix)
        solver.should have(27).solved_cells
      end
    end

    describe "#method" do
      it "returns :deduction by default" do
        solver.method.should == :deduction
      end

      it "sets it to something on demand" do
        solver.stub(:solved?).and_return(:true) # So that we’ll return immediately after the deduce phase
        solver.setup(:method => :guess)
        solver.method.should == :guess
      end
    end

    describe "#validating?" do
      it "only checks for validity if @params[:validating] is set" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.setup(:validating => true)
        solver.solve
        solver.should_not be_solved
      end

      it "returns true for a valid grid" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.setup(:validating => true)
        output.should_receive(:puts).with("Grid is valid.")
        solver.solve
      end

      context "with some unnecessary long string" do
        let(:ascii_art) { "+---+---+---+\n|8.6|.7.|45.|\n|7..|..4|693|\n|..4|...|8.7|\n+---+---+---+\n|..1|8.7|2.6|\n|.6.|4.2|.7.|\n|2.7|3.6|1..|\n+---+---+---+\n|4.3|...|9..|\n|612|5..|..4|\n|.58|.4.|3.2|\n+---+---+---+\n" }

        it "does print the ASCII-art grid for a normal run." do
          solver.setup(:validating => false)
          output.should_receive(:puts).with(ascii_art)
          solver.run([read_grid_file('simple.sdk')])
        end

        it "does not print the ASCII-art grid for a validating run" do
          solver.ingest(read_grid_file('simple.sdk'))
          solver.setup(:validating => true)
          output.should_not_receive(:puts).with(ascii_art)
          solver.solve
        end
      end
    end

    describe '#parse_file' do
      let(:grid_dir) { File.expand_path('../../../grids', __FILE__) }
      let(:gridfile) { File.join(grid_dir, 'guardian/2084.sdk') }

      it "parses the file" do
        solver.parse_file(gridfile)
        # TODO Test that the grid is correctly input
      end

      it "outputs a message" do
        output.should_receive(:puts).with("Parsing file #{gridfile}.")
        solver.parse_file(gridfile)
      end

      it "stores the file name somewhere" do
        solver.ingest(gridfile)
        solver.filename.should == gridfile
      end

      it "stores the original grid somewhere" do
        solver.ingest(gridfile)
        # TODO Matcher for that, as usual
        solver.original_grid.class.should == Hash
        solver.original_grid.all? { |k, v| v == solver.cell(k) }
      end
    end

    describe "#guess" do
      it "solves with the :guess method" do
        solver = Grid.new
        solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        solver.solve(:method => :guess)
        solver.should be_solved
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
        solver.ingest(read_grid_file('simple.sdk'))
        solver.should_not be_referenced
        solver.setup(:references => true)
        solver.should be_referenced
      end
    end

    describe "#solve" do
      it "sets additional options" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.should_not be_verbose
        solver.solve(:verbose => true)
        solver.should be_verbose
      end

      it "solves an easy grid" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        # Not sure whether to test that.
        # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
        solver.solve
        solver.should be_solved
      end

      it "calls reference if called with references" do # OK, that’s a little cryptic ...
       pending "Renegociation of responsibilities" do
         solver.ingest(read_grid_file('simple.sdk'))
         solver.should_receive(:reference)
         solver.solve(:references => true)
        end
      end

      it "is not trivial" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.solve
        solver.reference.should be_equal solver
      end
    end

    describe "#reference" do
      it "computes a reference solution grid" do
        solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        solver.reference.should act_as_a_solved_grid
      end

      it "catches some nasty inconsistencies" do
        solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        solver.stub_chain(:reference, :cell, :value).and_return(3)
        expect { solver.solve(:references => true, :chains => true) }.to raise_error(DiffersFromReference)
      end
    end

    describe "#run" do
    let(:griddir) { File.expand_path('../../../grids', __FILE__) }

      it "runs a simple file" do
        solver.run([File.join(griddir, 'simple.sdk')])
      end
    end

    describe "#deadlock?" do
      it "never uses deadlock?" do
        solver.should_not_receive(:deadlock?)
        solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        solver.solve(:verbose => true, :method => :guess, :chains => true)
      end
    end

    describe "#safe_solve" do
      it "never raises" do
        solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        solver.safe_solve
        solver.should_not be_solved
      end
    end
  end
end
