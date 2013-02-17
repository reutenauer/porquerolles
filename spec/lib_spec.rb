require 'spec_helper'
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
  describe '#find_chains' do
    it 'works' do
      solver = SudokuSolver.new(File.expand_path('X-wing.sdk', File.dirname(__FILE__)))
      grid = solver.grid
      solver.solve
      grid.find_chains
    end
  end
end
