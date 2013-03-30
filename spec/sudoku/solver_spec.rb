# encoding: UTF-8
require 'spec_helper'

# TODO Describe option passing!

module Sudoku
  describe Solver do
    let(:output) { double("output").as_null_object }
    let(:solver) { Solver.new(output) }

    describe "#new" do
      it "instantiates a new solver, outputting to /dev/null" do
        Solver.new
      end

      it "instantiates a new solver, writing to some output" do
        Solver.new(output)
      end
    end

    describe "#parse_options" do
      it "passes the verbose option" do
        Solver.parse_options(['-v'])[:verbose].should be_true
      end

      it "passes the quiet option, as “non-verbose”" do
        Solver.parse_options(['-q'])[:verbose].should be_false
      end

      it "passes the quiet option, overriding verbose" do
        Solver.parse_options(['-v', '-q'])[:verbose].should be_false
      end

      it "passes two options using the compact syntax" do
        options = Solver.parse_options(['-vc'])
        options[:verbose].should be_true
        options[:chains].should be_true
      end

      it "doesn’t hang on unknown options" do
        Solver.parse_options(['-f', "dummy name"])
      end
    end

    describe "options in action" do
      describe "verbose" do
        let(:output) { double('output').as_null_object }
        let(:solver) { Solver.new(output) }

        it "is verbose" do
          solver.solve(:verbose => true, :chains => true)
          solver.should be_verbose
          pending "needs refactoring between Grid and Solver" do
            solver.setup(:verbose => true)
          end
        end

        it "outputs extra messages" do
          pending "chains does not work yet" do
            output.should_receive(:puts).with("One more chain, total 19.  Latest chain [6, [[3, 8], [8, 8]], Column 8].  Total length 3.")
            solver.ingest(read_grid_file('misc/X-wing.sdk'))
            solver.solve(:verbose => true, :chains => true)
          end
        end
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
        solver.parse_file(gridfile)
        # TODO Test that the grid is correctly input
      end

      it "outputs a message" do
        output.should_receive(:puts).with("Parsing file #{gridfile}.")
        solver.parse_file(gridfile)
      end
    end

    describe "#solve" do
      it "solves an easy grid" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        # Not sure whether to test that.
        # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
        solver.solve
        solver.should be_solved
      end
    end
  end
end
