module Ruby2D
  class Table < Arena

    def init(margin: 6, **plan)
      plan[:color] ||= 0;
      @body = new_rectangle(**plan)
      care @body
      @margin = pot << margin
      @fit_grid = FitGrid.new x: @body.x, y: @body.y
      @body.width << @fit_grid.width
      @body.height << @fit_grid.height
      @current_x = -1
      @current_y = -1
    end

    delegate body: %w[fill plan x y width height left right top bottom]
    cvs_reader :margin

    def build
      super
      @fit_grid.finish
    end

    def row
      @current_y += 1
      yield
      @current_x = -1
    end

    builder_method :row

    def append(element, **plan, &b)
      if element.is_a? BoxContainer
        @current_x += 1
        @current_y = 0 if @current_y < 0
        @fit_grid.arrange(element, @current_x, @current_y, finish: false)
        r = new_rectangle color: '#444444', border: 1
        r.fill @fit_grid[@current_x, @current_y]
        care r
        care element
        if block_given? && element.is_a?(Arena)
          self.class.push_build_stack element do
            element.build(&b)
          end
        end
        return element
      else
        box gap: 3, **plan do |bx|
          bx.append(element, &b)
        end
      end
    end
  end
end
