require 'optparse'

module Sudoku
  class Options
    def self.parse(args)
      params = { }

      OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [options] <file name>"

        opts.on('-s', "--[no]-singles", "Place single candidates") do |s|
          params[:singles] = s
        end

        opts.on('-d', "--deduction", "Use deduction method") do
          params[:method] = :deduction
        end

        opts.on('-c', "--[no-]chains", "Find chains") do |c|
          params[:chains] = c
        end

        opts.on('-g', "--guess", "Use guess method") do
          params[:method] = :guess
        end

        opts.on('-v', "--[no-]verbose", "Be more verbose") do |v|
          params[:verbose] = v
        end

        opts.on('-q', "--[no-]quiet", "Be quieter") do |q|
          # Note: if we only use the key :verbose, the defaults are correct (i. e., quiet).
          params[:verbose] = !q
        end

        # No tree yet.

        begin
          opts.parse!(args)
        rescue OptionParser::InvalidOption => message
          puts "Error: #{message}"
          puts opts
        end
      end

      params
    end
  end
end
