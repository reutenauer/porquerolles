Feature: Invoking the solver from the command line

  As a command-line user
  I want to run the solver from my familiar environment with different switches
  so that I can explore all the options

  Scenario: Without any switch
    Given grid "simple.sdk"
    When I run with no switch
    Then it should solve the sudoku

  Scenario: With the chains switch
    Given grid "guardian/2423.sdk"
    When I run with switch -c
    Then it should solve the sudoku

  @super_slow
  Scenario: With the guess switch
    Given grid "maman.sdk"
    When I run with switch -g
    Then it should solve the sudoku

  Scenario: With both chains and guess
    Given grid "misc/X-wing.sdk"
    When I run with switch -c
    And I run with switch -g
    Then it should solve the sudoku

  Scenario: With the singles and chains switch
    Given grid "misc/X-wing.sdk"
    When I run with switch -s
    And I run with switch -c
    Then it should do its best to solve the sudoku

  Scenario: With only chains
    Given grid "misc/X-wing.sdk"
    When I run with switch -c
    Then it should do its best to solve the sudoku
