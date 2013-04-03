# encoding: UTF-8

RSpec::Matchers.define :act_as_a_solved_grid do # because “be_a” would look to much like automatic matchers
  match do |actual|
    actual.class == Sudoku::Grid && actual.solved?
  end
end
