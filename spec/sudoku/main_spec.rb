sudokubin = File.expand_path('../../../bin/sudoku', __FILE__)
griddir = File.expand_path('../../../grids', __FILE__)

describe "Main routine" do
  it "parses arguments in an awkward way" do
    `#{sudokubin} #{griddir}/simple.sdk` # Mutes command
  end
end
