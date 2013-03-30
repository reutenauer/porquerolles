# encoding: UTF-8
require 'spec_helper'

module Sudoku
  describe "options" do
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
