require 'spec_helper'

module Sudoku
  describe "Bug fixed :-)" do
    it "is works" do
      solver = Solver.new(STDOUT)
      solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
      solver.solve(:method => :guess)
      solver.should be_solved
    end
  end
end
