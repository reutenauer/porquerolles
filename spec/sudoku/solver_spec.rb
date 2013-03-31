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
        solver.parse_options(['-v'])
        solver.should be_verbose
      end

      it "passes the quiet option, as “non-verbose”" do
        solver.parse_options(['-q'])
        solver.should_not be_verbose
      end

      it "passes the quiet option, overriding verbose" do
        solver.parse_options(['-v', '-q'])
        solver.should_not be_verbose
      end

      it "passes two options using the compact syntax" do
        solver.parse_options(['-vc'])
        solver.should be_verbose
        solver.should be_chains
        pending "Ridiculous name"
      end

      it "passes the “references” options" do
        solver.parse_options(['-r'])
        solver.should be_referenced
      end

      it "outputs a message when it encounters an unknown options" do
        output.should_receive(:puts).with("Error: invalid option: -f")
        solver.parse_options(['-f'])
      end

      it "outputs extra messages when verbose" do
        pending "chains does not work yet" do
          output.should_receive(:puts).with("One more chain, total 19.  Latest chain [6, [[3, 8], [8, 8]], Column 8].  Total length 3.")
          solver.ingest(read_grid_file('misc/X-wing.sdk'))
          solver.solve(:verbose => true, :chains => true)
        end
      end

      it "solves using the chains option" do
        pending "chains does not yet work" do
          solver.ingest(read_grid_file('misc/X-wing.sdk'))
          solver.solve(:chains => true)
          solver.should be_solved
        end
      end
    end

    describe "#ingest" do
      it "ingests a grid from a file" do
        solver.ingest(read_grid_file('guardian/2084.sdk'))
      end
    end

    describe "#method" do
      it "returns :deduction by default" do
        solver.method.should == :deduction
      end

      it "sets it to something on demand" do
        solver.stub(:solved?).and_return(:true) # So that we’ll return immediately after the deduce phase
        solver.solve(:method => :guess)
        solver.method.should == :guess
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

      it "stores the file name somewhere" do
        pending "not implemented" do
          solver.parse_file(gridfile)
          solver.filename.should == gridfile
        end
      end

      it "stores the original grid somewhere" do
        pending "not implemented" do
          solver.parse_file(gridfile)
          # TODO Matcher for that, as usual
          solver.original_grid.class.should == Hash
          solver.original_grid.all? { |k, v| v == solver.cell(k) }
        end
      end
    end

    describe "#guess" do
      it "solves with the :guess method (using pseudo-random number generator, 5 runs)" do
        5.times do
          solver = Solver.new
          solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
          solver.solve(:method => :guess)
          solver.should be_solved
        end
      end
    end

    describe "#solve" do
      it "sets additional options" do
        solver.should_not be_verbose
        solver.solve(:verbose => true)
        solver.should be_verbose
      end

      it "sets yet other options" do
        solver.should_not be_referenced
        solver.solve(:references => true)
        solver.should be_referenced
      end

      it "solves an easy grid" do
        solver.ingest(read_grid_file('guardian/2423.sdk'))
        # Not sure whether to test that.
        # expect { solver.solve }.to change(solver, :nb_cell_solved) by(57)
        solver.solve
        solver.should be_solved
      end

      it "calls reference if called with references" do # OK, that’s a little cryptic ...
       pending
       solver.should_receive(:reference)
       solver.solve(:references => true)
      end

      it "is not trivial" do
         pending "address the ridiculous case when grid is fully solved"
      end
    end

    describe "#reference" do
      it "computes a reference solution grid" do
        pending "Big merger" do
          solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
          solver.reference.class.should == Grid
          solver.reference.should be_solved
          solver.should_not be_solved
        end
      end
    end

    describe "#run" do
    let(:griddir) { File.expand_path('../../../grids', __FILE__) }

      it "runs a simple file" do
        solver.run([File.join(griddir, 'simple.sdk')])
      end
    end
  end
end
