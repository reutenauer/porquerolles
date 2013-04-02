module Sudoku
  class Deadlock < Exception
  end

  class Paradox < Exception
  end

  class DiffersFromReference < Exception
  end

  class NoGridInput < Exception
  end
end
