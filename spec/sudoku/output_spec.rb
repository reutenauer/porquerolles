require 'spec_helper'

module Sudoku
  describe NullOutput do
    let(:output) { NullOutput.new }

    describe "#puts" do
      it "outputs nothing" do
        STDOUT.should_not_receive(:puts)
        output.puts("This is not a message.")
      end
    end

    describe "#print" do
      it "outputs nothing either" do
        STDOUT.should_not_receive(:print)
        output.print("This is not a message either.")
      end
    end
  end
end
