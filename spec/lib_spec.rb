require File.expand_path('../lib.rb', File.dirname(__FILE__))

describe Block do
  describe '#place_single' do
    it 'works' do
      solver = SudokuSolver.new
      grid = Grid.new(solver.parse_file(File.expand_path('../grids/guardian/2423.sdk', File.dirname(__FILE__))))
      block = grid.blocks.first

      1.upto(9) do |x|
        block.place_single(x)
      end
    end

    it 'places one value on one single values' do
      solver = SudokuSolver.new(File.expand_path('../grids/simple.sdk', File.dirname(__FILE__)))
      grid = solver.grid
      block = grid.blocks.last

      puts "Propagating ..."
      solver.propagate
      puts grid[6, 7].inspect
      solver.print

      puts "place_single(1) ..."
      block.place_single(1)
      puts grid[6, 7].inspect
      solver.print
      grid[6, 7].value.should == 1
    end
  end
end

describe Grid do
  context "with an empty grid" do
    let(:grid) { @grid = Grid.new }

    describe ".row_of" do
      it "finds the row of one cell" do
        grid.row_of([2, 3]).should == grid.rows[2]
      end
    end

    describe ".column_of" do
      it "finds the column on one cell" do
        grid.column_of([4, 6]).should == grid.columns[6]
      end
    end

    describe ".block_of" do
      it "finds the block of some cells" do
        grid.block_of([6, 6]).should == grid.blocks[8]
        grid.block_of([4, 3]).should == grid.blocks[4]
        grid.block_of([4, 4]).should == grid.blocks[4]
        grid.block_of([2, 8]).should == grid.blocks[2]
      end
    end

    describe "#groups_of" do
      it "finds the groups to which one cell belongs" do
        grid.groups_of([4, 6]).should =~ [grid.rows[4], grid.columns[6], grid.blocks[5]]
      end
    end
  end

  describe '#find_chains' do
    it 'find a link' do
      solver = SudokuSolver.new(File.expand_path('X-wing.sdk', File.dirname(__FILE__)))
      grid = solver.grid
      solver.solve
      grid.find_chains.should == [[6, [[3, 8], [8, 8]], grid.columns[8]]]
    end
  end
end
