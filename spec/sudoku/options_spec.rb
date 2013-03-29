# encoding: UTF-8
require 'spec_helper'

module Sudoku
  describe Options do
    describe "option passing" do
      it "passes the verbose option" do
        Options.parse(['-v'])[:verbose].should be_true
      end

      it "passes the quiet option, as “non-verbose”" do
        Options.parse(['-q'])[:verbose].should be_false
      end

      it "passes the quiet option, overriding verbose" do
        Options.parse(['-v', '-q'])[:verbose].should be_false
      end
    end
  end
end
