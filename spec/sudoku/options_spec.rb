# encoding: UTF-8
require 'spec_helper'

module Sudoku
  describe Options do
    describe "option passing" do
      it "passes the verbose option" do
        Options.parse(['-v', "dummy name"])[:verbose].should be_true
      end

      it "passes the quiet option, as “non-verbose”" do
        Options.parse(['-q', "dummy name"])[:verbose].should be_false
      end

      it "passes the quiet option, overriding verbose" do
        Options.parse(['-v', '-q', "dummy name"])[:verbose].should be_false
      end
    end

    describe "options in action" do
      describe "verbose" do
        let(:output) { double('output').as_null_object }
        let(:solver) { Solver.new(output) }

        it "is verbose" do
          output.should_receive(:puts).with("One more chain, total 19.  Latest chain [6, [[3, 8], [8, 8]], Column 8].  Total length 3.")
          solver.ingest(read_grid_file('misc/X-wing.sdk'))
          solver.solve(:verbose => true, :chains => true)
        end
      end
    end
  end
end
