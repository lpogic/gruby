module Ruby2D
  class Grid
    include CommunicatingVesselSystem
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

    cvs_reader :width, :height, :right, :bottom, :x, :y, :left, :top, :cols, :rows

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
      left = case cols
      when Integer then let(@cols[...cols].sum, @left).sum
      when Range then let(@cols[...cols.min].sum, @left).sum
      end
      width = case cols
      when Integer then @cols[cols]
      when Range then @cols[cols].sum
      end
      top = case rows
      when Integer then let(@rows[...rows].sum, @top).sum
      when Range then let(@rows[...rows.min].sum, @top).sum
      end
      height = case rows
      when Integer then @rows[rows]
      when Range then @rows[rows].sum
      end

      Sector.new(left:, width:, top:, height:)
    end

    alias_method :[], :sector

    def col(index)
      @cols.get[index]
    end

    def row(index)
      @rows.get[index]
    end
  end
end
