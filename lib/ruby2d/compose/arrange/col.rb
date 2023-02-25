module Ruby2D
  class Col < ColRowContainer
    def init(gap: 0, **ona)
      super
      @width_mix = pot []
      @width_mix.value <<= ona[:width] if ona[:width]
      @body.width << @width_mix.arrpot.as { _1.max || 0 }
      @grid = Grid.new cols: [@body.width], rows: [@start_gap, @end_gap], x: @body.x, y: @body.y
      @body.height << @grid.height
    end

    def append(element, **plan, &b)
      if element.is_a? Gap
        @grid.rows.set { |a| a[...-1] + [element.size, a[-1]] }
        @last_gap = true
      else
        if @last_gap
          @grid.rows.set { |a| a[...-1] + [element.height, a[-1]] }
        else
          @grid.rows.set { |a| a[...-1] + [@gap, element.height, a[-1]] }
        end
        @last_gap = false

        if plan[:width] == false
          plan.delete :width
        elsif !width.affect(plan[:width])
          @width_mix.value <<= element.width
        end

        super
      end
      return element
    end

    attr_reader :width_mix
  end
end
