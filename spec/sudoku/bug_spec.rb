require 'spec_helper'

module Sudoku
  describe "Bug ahead!" do
    it "is buggy" do
      solver = Solver.new(STDOUT)
      solver.ingest(read_grid_file('sotd/2013-02-05-diabolical.sdk'))
      solver.solve(:method => :guess)
      solver.should be_solved
    end
  end
end
