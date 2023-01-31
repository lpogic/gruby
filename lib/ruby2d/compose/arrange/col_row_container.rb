module Ruby2D
  class ColRowContainer < Cluster
    def init(gap: 0, **ona)
      ona[:color] ||= 0
      care @body = new_rectangle(**ona)
      @start_gap = pot
      @gap = pot
      @end_gap = pot
      self.gap = gap
      @last_gap = true
    end

    def append(element, **plan)
      gs = @grid.sector(@grid.cols.get.length - 2, @grid.rows.get.length - 2, fixed: false)
      plan[:x] = gs.x unless Rectangle.x_dim? plan
      plan[:y] = gs.y unless Rectangle.y_dim? plan
      element.plan(**plan)
      care element
    end

    delegate body: %w[fill plan left top right bottom x y width height color round]
    attr_reader :body, :grid

    def gap=(gap)
      if gap.is_a? Array
        case gap.size
        when 1
          @start_gap << gap[0]
          @gap << gap[0]
          @end_gap << gap[0]
        when 2
          @start_gap << gap[0]
          @gap << gap[1]
          @end_gap << gap[0]
        when 3
          @start_gap << gap[0]
          @gap << gap[1]
          @end_gap << gap[2]
        else
          raise "Invalid gap array size #{gap}"
        end
      else
        @start_gap << 0
        @gap << gap
        @end_gap << 0
      end
    end
  end
end
