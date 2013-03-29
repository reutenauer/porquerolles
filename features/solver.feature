Feature: Unnamed

  Not sure what I’m testing here exactly.

  Scenario: The solver solves
    Given grid "maman.sdk"
    When I use the guess method
    Then the solver should solve the sudoku
