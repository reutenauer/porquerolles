def run(file)
  sudokubin = File.expand_path('../../../bin/sudoku', __FILE__)
  griddir = File.expand_path('../../../grids', __FILE__)

  `#{sudokubin} #{File.join(griddir, file)}` # Mutes command
end

describe "Main routine" do
  it "parses arguments in an awkward way" do
    run('simple.sdk')
  end
end
