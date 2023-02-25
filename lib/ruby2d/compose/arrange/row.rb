module Ruby2D
  class Row < ColRowContainer
    def init(gap: 0, **ona)
      super
      @height_mix = pot []
      @height_mix.value <<= ona[:height] if ona[:height]
      @body.height << @height_mix.arrpot.as { _1.max || 0 }
      @grid = Grid.new rows: [@body.height], cols: [@start_gap, @end_gap], x: @body.x, y: @body.y
      @body.width << @grid.width
    end

    def append(element, **plan, &b)
      if element.is_a? Gap
        @grid.cols.set { |a| a[...-1] + [element.size, a[-1]] }
        @last_gap = true
      else
        if @last_gap
          @grid.cols.set { |a| a[...-1] + [element.width, a[-1]] }
        else
          @grid.cols.set { |a| a[...-1] + [@gap, element.width, a[-1]] }
        end
        @last_gap = false

        if plan[:height] == false
          plan.delete :height
        elsif !height.affect(plan[:height])
          @height_mix.value <<= element.height
        end

        super
      end
      return element
    end

    attr_reader :height_mix
  end
end
