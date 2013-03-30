# encoding: UTF-8
require 'spec_helper'

module Sudoku
  describe Options do
    describe "option passing" do
      it "passes the verbose option" do
        Options.parse(['-v', "dummy name"])[:verbose].should be_true
        pending "freezes for the moment"
        Options.parse(['-f']).should work_as_well
      end

      it "passes the quiet option, as “non-verbose”" do
        Options.parse(['-q', "dummy name"])[:verbose].should be_false
      end

      it "passes the quiet option, overriding verbose" do
        Options.parse(['-v', '-q', "dummy name"])[:verbose].should be_false
      end

      it "passes two options using the compact syntax" do
        pending "needs implementation"
        options = Options.parse(['-vc', "dummy name"])
        options[:verbose].should be_true
        options[:chains].should be_true
      end

      it "doesn’t hang on unknown options" do
        Options.parse(['-f', "dummy name"])
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
  end
end
