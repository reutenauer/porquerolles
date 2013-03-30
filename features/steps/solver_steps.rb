# Given is in command_line_steps.rb

include Sudoku

When /^I use the ([a-z]*) method$/ do |method|
  @params ||= { }
  @params[:method] = method.to_sym
end

Then /^the solver should solve the sudoku$/ do
  solver = Solver.new
  solver.ingest(File.expand_path("../../../grids/#{@gridfile}", __FILE__))
  solver.solve(@params)
  solver.grid.solved?.should be_true
end