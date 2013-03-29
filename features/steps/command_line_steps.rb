Given /^grid "([^"]*)"$/ do |grid|
  @gridfile = grid
  @switches = []
end

When /^I run with no switch$/ do
end

When /^I run with switch (-[a-z])$/ do |switch|
  @switches << switch
end

Then /^it should solve the sudoku$/ do
  sudokubin = File.expand_path('../../../bin/sudoku', __FILE__)
  `#{sudokubin} #{@switches.join(' ')} #{@gridfile}`
end
