Feature: Solving

  Not sure what I’m testing here exactly.

  @slow
  Scenario: The solver solves
    Given grid "maman.sdk"
    When I use the guess method
    Then the solver should solve the sudoku

  Scenario: The solver never fails
    Given grid "sotd/2013-02-05-diabolical.sdk"
    When I use the guess method 5 times over
    Then the solver should solve the sudoku
