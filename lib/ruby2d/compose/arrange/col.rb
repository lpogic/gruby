module Ruby2D
  class Col < ColRowContainer
    def init(gap: 0, **ona)
      super
      let(ona[:width] || 0, @objects.arrpot { _1 == @body || width.affect(_1.width) ? nil : _1.width }) { [_1, _2.max || 0].max } >> @body.width
      @grid = Grid.new cols: [@body.width], x: @body.x, y: @body.y
      @body.height << @grid.height
    end

    def append(element, **plan)
      if element.is_a? Gap
        @grid.rows.set { |a| a + [element.size] }
        @last_gap = true
      else
        if @last_gap
          @grid.rows.set { |a| a + [element.height] }
        else
          @grid.rows.set { |a| a.empty? ? [element.height] : a + [@gap, element.height] }
        end
        @last_gap = false
        super

      end
    end
  end
end
