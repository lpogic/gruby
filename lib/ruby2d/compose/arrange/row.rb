module Ruby2D
  class Row < ColRowContainer
    def init(gap: 0, **ona)
      super
      let(ona[:height] || 0, @objects.arrpot { _1 == @body || height.affect(_1.height) ? nil : _1.height }) { [_1, _2.max || 0].max } >> @body.height
      @grid = Grid.new rows: [@body.height], x: @body.x, y: @body.y
      @body.width << let(ona[:width] || 0, @grid.width) { [_1, _2].max }
    end

    def append(element, **plan)
      if element.is_a? Gap
        @grid.cols.set { |a| a + [element.size] }
        @last_gap = true
      else
        if @last_gap
          @grid.cols.set { |a| a + [element.width] }
        else
          @grid.cols.set { |a| a.empty? ? [element.width] : a + [@gap, element.width] }
        end
        @last_gap = false
        super
      end
    end
  end
end
