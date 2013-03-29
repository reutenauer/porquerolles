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
  end
end
