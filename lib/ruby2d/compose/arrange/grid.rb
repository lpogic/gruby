module Ruby2D
  class Grid
    include CommunicatingVesselSystem
    include Planned

    def initialize(cols: [], rows: [], **na)
      @left = pot 100
      @top = pot 100
      @width = pot 0
      @height = pot 0
      @cols = arrpot.let cols
      @width << @cols.sum
      @rows = arrpot.let rows
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

    def sector(col, row, fixed: true)
      if fixed
        left = case col
               when Integer then let(*@cols.get[0...col], @left).sum
               when Range then let(*@cols.get[0...col.min], @left).sum
        end
        width = case col
                when Integer then @cols.get[col]
                when Range then let(*@cols.get[col]).sum
        end
        top = case row
              when Integer then let(*@rows.get[0...row], @top).sum
              when Range then let(*@rows.get[0...row.min], @top).sum
        end
        height = case row
                 when Integer then @rows.get[row]
                 when Range then let(*@rows.get[row]).sum
        end
      else
        left = case col
               when Integer then let(@cols[...col].sum, @left).sum
               when Range then let(@cols[...col.min], @left).sum
        end
        width = case col
                when Integer then @cols[col]
                when Range then @cols[col].sum
        end
        top = case row
              when Integer then let(@rows[...row].sum, @top).sum
              when Range then let(@rows[...row.min].sum, @top).sum
        end
        height = case row
                 when Integer then @rows[row]
                 when Range then @rows[row].sum
        end
      end

      Sector.new(left:, width:, top:, height:)
    end

    alias [] sector

    def col(index)
      @cols.get[index]
    end

    def row(index)
      @rows.get[index]
    end
  end
end
