require 'spec_helper'

describe SudokuSolver do
  describe "#solve" do
    it "solves an easy grid" do
      solver = SudokuSolver.new(open_grid('guardian/2423.sdk'))
      # Not sure whether to test that.
      # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
      solver.solve
      # TODO Matcher for that!
      solver.nb_cell_solved.should == 81
    end

    it "solves a hard grid", :slow => true do
      solver = SudokuSolver.new(open_grid('maman.sdk'))
      solver.solve
      solver.nb_cell_solved.should == 24

      solver.solve(:method => :guess)
      solver.nb_cell_solved.should == 81
    end
  end
end
