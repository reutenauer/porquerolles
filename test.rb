require 'sudoku'
solver = SudokuSolver.new "simple.sdk"
solver.print
solver.solve
puts solver.solved?
solver.print

solver_diabolical = SudokuSolver.new "diabolical.sdk"
solver_diabolical.print
solver_diabolical.solve
puts solver_diabolical.solved?
solver_diabolical.print
