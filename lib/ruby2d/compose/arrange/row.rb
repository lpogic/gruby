module Ruby2D
  class Row < ColRowContainer
    def init(gap: 0, **ona)
      super
      @height_mix = pot []
      @height_mix.value <<= ona[:height] if ona[:height]
      @body.height << @height_mix.arrpot.as{ _1.max || 0 }
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

        if plan[:height] == :off
          plan.delete :height
        elsif !height.affect(plan[:height])
          @height_mix.value <<= element.height
        end

        super
      end
    end

    def height_mix; @height_mix end
  end
end
