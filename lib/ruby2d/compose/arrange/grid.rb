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

    def sector(cols, rows, fixed: false)
      pick = fixed ?
        proc{|ap, i| ap.get[i]} :
        proc{|ap, i| ap[i]}

      left = case cols
      when Integer then let(pick.(@cols, ...cols).sum, @left).sum
      when Range then let(pick.(@cols, ...cols.min).sum, @left).sum
      end
      width = case cols
      when Integer then pick.(@cols, cols)
      when Range then pick.(@cols, cols).sum
      end
      top = case rows
      when Integer then let(pick.(@rows, ...rows).sum, @top).sum
      when Range then let(pick.(@rows, ...rows.min).sum, @top).sum
      end
      height = case rows
      when Integer then pick.(@rows, rows)
      when Range then pick.(@rows, rows).sum
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
