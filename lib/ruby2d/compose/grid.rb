module Ruby2D
    class Grid
        include CommunicatingVesselSystem
        include Planned
     
        def initialize(cols: [], rows: [], **na)
           @left = pot(na[:left] || 100)
           @top = pot(na[:top] || 100)
           @width = pot
           @height = pot
           @cols = compot do |cols|
              let(*cols).sum >> @width
              [cols]
           end.set cols.map{pot _1}
           @rows = compot do |rows|
              let(*rows).sum >> @height
              [rows]
           end.set rows.map{pot _1}
     
           plan **na
        end
     
        cvs_accessor :left, :top, :cols, :rows
        cvs_reader :width, :height, :right, :bottom, :x, :y
     
        def _default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil)
         if x
            let(x, width){_1 - _2 * 0.5} >> @left
         elsif left
           let(left){_1} >> @left
         elsif right
           let(right, width){_1 - _2} >> @left
         end
   
         if y
            let(y, height){_1 - _2 * 0.5} >> @top
         elsif top
            let(top){_1} >> @top
         elsif bottom
            let(bottom, height){_1 - _2} >> @top
         end
       end
     
        def _cvs_right
         let(@left, @width){_1 + _2}
        end
     
        def _cvs_bottom
         let(@top, @height){_1 + _2}
        end
     
        def _cvs_x
            let(@left, @width){_1 + _2 * 0.5}
        end
     
        def _cvs_y
            let(@top, @height){_1 + _2 * 0.5}
        end
     
        class Sector
     
           hash_init :left, :width, :top, :height, reader: true
     
           def right
              let(@left, @width){_1 + _2}
           end
     
           def bottom
              let(@top, @height){_1 + _2}
           end
     
           def x
              let(@left, @width){_1 + _2 * 0.5}
           end
     
           def y
              let(@top, @height){_1 + _2 * 0.5}
           end
        end
     
        def sector(col, row)
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
     
           Sector.new(left: left, width: width, top: top, height: height)
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