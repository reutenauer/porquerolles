require 'spec_helper'

module Sudoku
  describe Solver do
    let(:solver) { Solver.new }
    let(:grid_dir) { File.expand_path('../../../grids', __FILE__) }

    describe "#ingest" do
      it "ingests a grid from a file" do
        solver.ingest(File.join(grid_dir, "guardian/2084.sdk"))
      end
    end

    describe "#solve" do
      it "solves an easy grid" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        # Not sure whether to test that.
        # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
        solver.solve
        # TODO Matcher for that!
        solver.nb_cell_solved.should == 81
      end

      it "solves a hard grid", :slow => true do
        solver.ingest(read_grid_file('maman.sdk'))
        solver.solve
        solver.nb_cell_solved.should == 24

        solver.solve(:method => :guess)
        solver.nb_cell_solved.should == 81
      end
    end
  end
end
