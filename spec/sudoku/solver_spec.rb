require 'spec_helper'

def open_file(file)
  File.expand_path(File.join('../../grids', file), File.dirname(__FILE__))
end

describe SudokuSolver do
  describe "#solve" do
    it "solves a couple of grids" do
      solver = SudokuSolver.new(open_file('guardian/2423.sdk'))
      # Not sure whether to test that.
      # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
      solver.solve
      # TODO Matcher for that!
      solver.nb_cell_solved.should == 81

      solver = SudokuSolver.new(open_file('maman.sdk'))
      solver.solve
      solver.nb_cell_solved.should == 24

      solver.solve(:method => :guess)
      solver.nb_cell_solved.should == 81
    end
  end
end
