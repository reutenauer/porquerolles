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

    describe "Command line calls" do
      def run(file, options = "")
        sudokubin = File.expand_path('../../../bin/sudoku', __FILE__)

        system("#{sudokubin} #{options} #{File.join(griddir, file)} >/dev/null").should be_true
      end

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
  end
end
