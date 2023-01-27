module Ruby2D
  class Col < ColRowContainer
    def init(gap: 0, **ona)
      super
      @width_mix = pot []
      @width_mix.value <<= ona[:width] if ona[:width]
      @body.width << @width_mix.arrpot.as{ _1.max || 0 }
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

        if plan[:width] == :off
          plan.delete :width
        elsif !width.affect(plan[:width])
          @width_mix.value <<= element.width
        end

        super
      end
    end

    def width_mix; @width_mix end
  end
end
