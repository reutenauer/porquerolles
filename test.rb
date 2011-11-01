require 'sudoku'
grids = ["simple", "average", "hard", "expert", "diabolical"]
grids.each do |name|
  solver = SudokuSolver.new "#{name}.sdk"
  solver.print
  solver.solve
  puts solver.solved?
  solver.print
end
