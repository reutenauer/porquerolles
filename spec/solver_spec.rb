require File.expand_path('../lib.rb', File.dirname(__FILE__))

describe SudokuSolver do
  describe "#solve" do
    it "solves a couple of grids" do
      solver = SudokuSolver.new(File.expand_path('../grids/guardian/2423.sdk', File.dirname(__FILE__)))
      # Not sure whether to test that.
      # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
      solver.solve
      # TODO Matcher for that!
      solver.nb_cell_solved.should == 81

      solver = SudokuSolver.new(File.expand_path('../grids/maman.sdk', File.dirname(__FILE__)))
      solver.solve
      solver.nb_cell_solved.should == 24

      solver.solve(:method => :guess)
      solver.nb_cell_solved.should == 81
    end
  end
end
