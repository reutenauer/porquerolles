module Sudoku
  class Options
    def self.parse(args)
      params = { }

      # TODO Play with optparse now.
      # TODO “$0 -f grid/maman.sdk” freezes
      while args.count > 1
        f = args.first

        if f == '-s'
          params[:singles] = true
          args.slice!(0)
        elsif f == '-d'
          params[:method] = :deduction
          args.slice!(0)
        elsif f == '-c'
          params[:chains] = true
          args.slice!(0)
        elsif f == '-g'
          params[:method] = :guess
          args.slice!(0)
        elsif f == '-v'
          params[:verbose] = true
          args.slice!(0)
        elsif f == '-q'
          # Note: if we only use the key :verbose, the defaults are correct (i. e., quiet).
          params[:verbose] = false
          args.slice!(0)
        # No tree yet.
        end
      end

      params
    end
  end
end
