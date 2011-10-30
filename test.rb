require 'sudoku'
solver = SudokuSolver.new "simple.sdk"
solver.print
solver.solve
puts solver.solved?
solver.print
