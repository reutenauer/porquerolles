require 'spec_helper'

module Sudoku
  describe Block do
    let(:solver) { Solver.new }

    describe '#place_single' do
      it "works" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        grid = solver.grid
        block = grid.blocks.first

        1.upto(9) do |x|
          block.place_single(x)
        end
      end

      it "places one value on one single values" do
        solver = Solver.new
        solver.ingest(read_grid_file('simple.sdk'))
        grid = solver.grid
        block = grid.blocks.last

        solver.propagate
        grid[6, 7].should_not be_solved
        grid[6, 7].should have(3).elements

        block.place_single(1)
        grid[6, 7].should be_solved
        grid[6, 7].value.should == 1
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
      let(:solver) { Solver.new }
      let(:grid) { solver.grid }

      it "finds a link" do
        solver.ingest(read_grid_file('misc/X-wing.sdk'))
        solver.solve
        # TODO Write a matcher for that too
        grid.find_chains.include?([6, [[3, 8], [8, 8]], grid.columns[8]]).should == true
      end

      it "does not crash" do
        pending "chains not working yet" do
          solver.ingest(read_grid_file('guardian/2423.sdk'))
          solver.solve(:chains => true)
        end
      end
    end
  end
end
