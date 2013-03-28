# encoding: UTF-8

def run(file, options = "")
  sudokubin = File.expand_path('../../../bin/sudoku', __FILE__)
  griddir = File.expand_path('../../../grids', __FILE__)

  system("#{sudokubin} #{options} #{File.join(griddir, file)}").should be_true
end

describe "Main routine" do
  it "runs main without any switch" do
    run('simple.sdk')
  end

  it "runs main with the “chains” switch" do
    run('guardian/2423.sdk', '-c')
  end

  it "runs main with the “guess” switch", :slow => true do
    run('maman.sdk', '-g')
  end

  it "runs main with both the “chains” and the “guess” switch" do
    run('misc/X-wing.sdk', '-c -g')
  end

  it "runs main with the “singles” and the “chains” switch" do
    run('misc/X-wing.sdk', '-s -c')
  end

  it "runs main with only the “chains” switch" do
    run('misc/X-wing.sdk', '-c')
  end
end
