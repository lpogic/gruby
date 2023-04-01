module Ruby2D
  class BoxContainer < Arena

    def init(gap: 0, **ona)
      ona[:color] ||= 0
      care @body = new_rect(**ona)
      @left_gap = pot
      @right_gap = pot
      @top_gap = pot
      @bottom_gap = pot
      self.gap = gap
      @width_mix = arrpot
      @height_mix = arrpot
      @width_mix.val <<= ona[:width] if ona[:width]
      @height_mix.val <<= ona[:height] if ona[:height]
      @grid = Grid.new(
        cols: [@left_gap, @width_mix.as { _1.max || 0 }, @right_gap], 
        rows: [@top_gap, @height_mix.as { _1.max || 0 }, @bottom_gap], 
        x: @body.x, 
        y: @body.y
      )
      @body.height << @grid.height
      @body.width << @grid.width
    end

    def append(element, **plan, &b)
      if plan[:width] == false
        plan.delete :width
      elsif !width.affect(plan[:width])
        @width_mix.val <<= element.width
      end
      if plan[:height] == false
        plan.delete :height
      elsif !height.affect(plan[:height])
        @height_mix.val <<= element.height
      end

      gs = @grid.sector(@grid.cols.get.length - 2, @grid.rows.get.length - 2)
      plan[:x] = gs.x unless Rectangle.x_dim? plan
      plan[:y] = gs.y unless Rectangle.y_dim? plan
      element.plan(**plan)
      care element
      if block_given? && element.is_a?(Arena)
        self.class.push_build_stack element do
          element.build(&b)
        end
      end
      return element
    end


    delegate body: %w[fill plan left top right bottom x y width height color round]
    attr_reader :body, :grid, :width_mix, :height_mix

    def gap=(gap)
      if gap.is_a? Array
        case gap.size
        when 1
          @left_gap << gap[0]
          @right_gap << gap[0]
          @top_gap << gap[0]
          @bottom_gap << gap[0]
        when 2
          @left_gap << gap[0]
          @right_gap << gap[0]
          @top_gap << gap[1]
          @bottom_gap << gap[1]
        when 4
          @left_gap << gap[0]
          @right_gap << gap[1]
          @top_gap << gap[2]
          @bottom_gap << gap[3]
        else
          raise "Invalid gap array size #{gap}"
        end
      else
        @left_gap << gap
        @right_gap << gap
        @top_gap << gap
        @bottom_gap << gap
      end
    end
  end
end
