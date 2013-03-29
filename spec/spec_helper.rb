require File.expand_path('../lib/sudoku', File.dirname(__FILE__))

def read_grid_file(file)
  File.expand_path(File.join('../grids', file), File.dirname(__FILE__))
end

RSpec.configure do |config|
  # config.filter_run :focus => true # FIXME Kind of an embarrassment
end
