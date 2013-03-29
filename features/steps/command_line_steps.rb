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
  # TODO Rename that step, it’s not really about solving fully.
  grid_dir = File.expand_path('../../../grids', __FILE__)
  sudokubin = File.expand_path('../../../bin/sudoku', __FILE__)
  system("#{sudokubin} #{@switches.join(' ')} #{File.join(grid_dir, @gridfile)} >/dev/null").should be_true
end
