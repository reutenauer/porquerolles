# encoding: UTF-8
require 'spec_helper'

describe Set do
  describe "#copy" do
    it "returns a copy of self" do
      set = Set.new([1, 2, 3])
      set2 = set.copy
      set2.object_id.should_not == set.object_id
      set2.to_a.should =~ set.to_a
      pending "Need to use better equality test"
    end
  end
end

module Sudoku
  describe Block do
    let(:solver) { Grid.new }

    describe "#data?" do
      it "refuses to do something useless" do
        pending "not yet implemented" do
          solver.stub(:data?).and_return(false)
          solver.should crash
        end
      end
    end

    describe "#set_solved" do
      it "is fussy if solver is referenced" do
        pending "needs refactoring"
        solver.ingest(read_grid_file('simple.sdk'))
        solver.solve(:references => true)
        solver.should_receive(:reference) # Very weak test, but OK ...
        solver.grid[1, 1].set_solved(1)
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

      it "is fussy if solver is referenced" do
        pending "needs refactoring"
        solver.ingest(read_grid_file('simple.sdk'))
        solver.solve(:references => true)
        solver.should_receive(:reference)
        solver.grid[8, 8].cross_out(8)
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

      it "really does what it should" # Above example is absurd and evidence that things don’t really work well
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

      it "does not crash" do
        pending "actually it does crash for the moment" do
          solver.ingest(read_grid_file('guardian/2423.sdk'))
          solver.solve(:chains => true)
        end
      end
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

      it "outputs a message when it encounters an unknown options" do
        output.should_receive(:puts).with("Error: invalid option: -f")
        solver.parse_options(['-f'])
      end

      it "outputs extra messages when verbose" do
        pending "chains does not work yet" do
          output.should_receive(:puts).with("One more chain, total 19.  Latest chain [6, [[3, 8], [8, 8]], Column 8].  Total length 3.")
          solver.ingest(read_grid_file('misc/X-wing.sdk'))
          solver.solve(:verbose => true, :chains => true)
        end
      end

      it "solves using the chains option" do
        pending "chains does not yet work" do
          solver.ingest(read_grid_file('misc/X-wing.sdk'))
          solver.solve(:chains => true)
          solver.should be_solved
        end
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
        solver.solve(:method => :guess)
        solver.method.should == :guess
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
        pending "not implemented" do
          solver.parse_file(gridfile)
          solver.filename.should == gridfile
        end
      end

      it "stores the original grid somewhere" do
        pending "not implemented" do
          solver.parse_file(gridfile)
          # TODO Matcher for that, as usual
          solver.original_grid.class.should == Hash
          solver.original_grid.all? { |k, v| v == solver.cell(k) }
        end
      end
    end

    describe "#guess", :focus => true do
      it "solves with the :guess method (using pseudo-random number generator, 5 runs)" do
        5.times do
          solver = Grid.new
          solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
          solver.solve(:method => :guess)
          solver.should be_solved
        end
      end
    end

    describe "#solve" do
      it "sets additional options" do
        solver.should_not be_verbose
        solver.solve(:verbose => true)
        solver.should be_verbose
      end

      it "sets yet other options" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.should_not be_referenced
        solver.solve(:references => true)
        solver.should be_referenced
      end

      it "solves an easy grid" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        # Not sure whether to test that.
        # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
        solver.solve
        solver.should be_solved
      end

      it "calls reference if called with references" do # OK, that’s a little cryptic ...
       solver.ingest(read_grid_file('simple.sdk'))
       solver.should_receive(:reference)
       solver.solve(:references => true)
      end

      it "is not trivial" do
        solver.ingest(read_grid_file('simple.sdk'))
        solver.solve
        solver.reference.object_id.should == solver.object_id # FIXME ugly
      end
    end

    describe "#reference" do
      it "computes a reference solution grid" do
        solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
        solver.reference.class.should == Grid
        solver.reference.should be_solved
        solver.should_not be_solved
        pending "Reference should be a matrix anyway"
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
        pending "Check why it breaks (raising Deadlock), and remove deadlock?, the method" do
          solver.should_not_receive(:deadlock?)
          solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
          solver.solve(:verbose => true, :method => :guess, :chains => true)
        end
      end
    end
  end
end
