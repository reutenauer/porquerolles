# encoding: UTF-8

require 'spec_helper'

module Sudoku
  describe Main do
    let(:griddir) { File.expand_path('../../../grids', __FILE__) }

    describe "Main routine" do
      it "runs a simple file" do
        Main.run([File.join(griddir, 'simple.sdk')])
      end
    end
  end
end
