module Ruby2D
  class ColRowContainer < Cluster
    def init(gap: 0, **ona)
      ona[:color] ||= 0
      care @body = new_rectangle(**ona)
      @gap = pot << gap
    end

    def append(element, **plan)
      gs = @grid.sector(@grid.cols.get.length - 1, @grid.rows.get.length - 1, fixed: false)
      plan[:x] = gs.x unless Rectangle.x_dim? plan
      plan[:y] = gs.y unless Rectangle.y_dim? plan
      element.plan(**plan)
      care element
    end

    delegate body: %w[fill plan left top right bottom x y width height color round]
    attr_reader :body, :grid
  end
end
