module Ruby2D
  class Grid
    include CVS
    include Planned

    def initialize(cols: [], rows: [], **na)
      @left = pot 100
      @top = pot 100
      @width = pot 0
      @height = pot 0
      @cols = arrpot << cols
      @width << @cols.sum
      @rows = arrpot << rows
      @height << @rows.sum

      plan(**na)
    end

    cvsa :width, :height, :right, :bottom, :x, :y, :left, :top, :cols, :rows

    def default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil)
      if x
        let(x, width) { _1 - (_2 * 0.5) } >> @left
      elsif left
        left >> @left
      elsif right
        let(right, width) { _1 - _2 } >> @left
      end

      if y
        let(y, height) { _1 - (_2 * 0.5) } >> @top
      elsif top
        top >> @top
      elsif bottom
        let(bottom, height) { _1 - _2 } >> @top
      end
    end

    def cvs_right
      let(@left, @width) { _1 + _2 }
    end

    def cvs_bottom
      let(@top, @height) { _1 + _2 }
    end

    def cvs_x
      let(@left, @width) { _1 + (_2 * 0.5) }
    end

    def cvs_y
      let(@top, @height) { _1 + (_2 * 0.5) }
    end

    class Sector
      def_struct :left, :width, :top, :height, readers: true

      def right
        let(@left, @width) { _1 + _2 }
      end

      def bottom
        let(@top, @height) { _1 + _2 }
      end

      def x
        let(@left, @width) { _1 + (_2 * 0.5) }
      end

      def y
        let(@top, @height) { _1 + (_2 * 0.5) }
      end
    end

    def sector(cols, rows)
      cols = cols..cols if not cols.is_a? Range
      rows = rows..rows if not rows.is_a? Range

      left = let @cols, cols, @left do |sc, c, l|
        sc[...c.min].sum + l
      end
      width = let @cols, cols do |sc, c|
        sc[c].sum
      end
      top = let @rows, rows, @top do |sr, r, t|
        sr[...r.min].sum + t
      end
      height = let @rows, rows do |sr, r|
        sr[r].sum
      end

      Sector.new(left:, width:, top:, height:)
    end

    alias_method :[], :sector

    def col(index)
      let @cols, index do
        _1[_2]
      end
    end

    def row(index)
      let @rows, index do
        _1[_2]
      end
    end
  end
end
