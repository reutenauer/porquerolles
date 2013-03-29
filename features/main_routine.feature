Feature: Invoking the solver from the command line

  As a command-line user
  I want to run the solver from my familiar environment with different switches
  so that I can explore all the options

  Scenario: Without any switch
    Given the command-line executable
    When I want to solve grid simple.sdk
    And I run with no switch
    Then it should solve the sudoku

  Scenario: With the chains switch
    Given the command-line executable
    When I want to solve grid guardian/2423.sdk
    And I run witch switch -c
    Then it should solve the sudoku

  Scenario: With the guess switch
    Given the command-line executable
    When I want to solve grid maman.sdk
    And I run with switch -g
    Then it should solve the sudoku

  Scenario: With both chains and guess
    Given the command-line executable
    When I want to solve grid misc/X-wing.sdk
    And I run with switch -c
    And I run with switch -g
    Then it should solve the sudoku

  Scenario: With the singles and chains switch
    Given the command-line executable
    When I want to solve grid misc/X-wing.sdk
    And I run with switch -s
    And I run with switch -c
    Then it should solve the sudoku

  Scenario: With only chains
    Given the command-line executable
    When I want to solve grid misc/X-wing.sdk
    And I run switch -c
    Then it should solve the sudoku
