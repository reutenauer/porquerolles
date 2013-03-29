require 'spec_helper'

module Sudoku
  describe Solver do
    let(:solver) { Solver.new }

    describe "#new" do
      it "instantiates a new solver, outputting to /dev/null" do
        Solver.new
      end

      let(:output) { double("output") }

      it "instantiates a new solver, writing to some output" do
        Solver.new(output)
      end
    end

    describe "#ingest" do
      it "ingests a grid from a file" do
        solver.ingest(read_grid_file('guardian/2084.sdk'))
      end
    end

    describe '#parse_file' do
      let(:grid_dir) { File.expand_path('../../../grids', __FILE__) }
      let(:gridfile) { File.join(grid_dir, 'guardian/2084.sdk') }

      it "parses the file" do
        Solver.parse_file(gridfile)
        # TODO Test that the grid is correctly input
      end

      it "outputs a message" do
        output.should_receive(:puts).with(gridfile)
        Solver.parse_file(gridfile)
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
