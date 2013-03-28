require File.expand_path('../lib/sudoku', File.dirname(__FILE__))

def open_grid(file)
  File.expand_path(File.join('../grids', file), File.dirname(__FILE__))
end
