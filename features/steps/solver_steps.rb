# Given is in command_line_steps.rb

include Sudoku

When /^I use the ([a-z]*) method(?: ([\d]+) times over)?$/ do |method, times|
  @params ||= { }
  @params[:method] = method.to_sym
  if times == ""
    @times = 1
  else
    @times = times.to_i
  end
end

Then /^the solver should solve the sudoku$/ do
  @times.times do
    solver = Grid.new
    solver.ingest(File.expand_path("../../../grids/#{@gridfile}", __FILE__))
    solver.solve(@params)
    solver.should be_solved
  end
end
