require 'sudoku'
solver = SudokuSolver.new "simple.sdk"
solver.print
puts solver.solved?
solver.propagate
solver.print
puts solver.solved?
