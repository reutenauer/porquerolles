require File.expand_path('../lib.rb', File.dirname(__FILE__))

describe "SudokuSolver" do
  describe "#solve" do
    it "solves the grid" do
      solver = SudokuSolver.new(File.expand_path('../grids/guardian/2423.sdk', File.dirname(__FILE__)))
      # expect { solver.solve }.to change(solver, :nb_cell_solved) by(81)
      solver.solve
      solver.nb_cell_solved.should == 81
    end
  end
end
