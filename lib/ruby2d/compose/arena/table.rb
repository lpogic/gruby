module Ruby2D
  class Table < Arena

    def init(gap: 6, **plan)
      plan[:color] ||= 0;
      @body = new_rect(**plan)
      care @body
      @gap = pot << gap
      @fit_grid = FitGrid.new x: @body.x, y: @body.y
      @body.width << @fit_grid.width
      @body.height << @fit_grid.height
      @current_x = -1
      @current_y = -1
    end

    def close!
      @fit_grid.arrange
    end

    delegate body: %w[fill plan x y width height left right top bottom]
    cvsa :gap

    def row!
      @current_y += 1
      yield
      @current_x = -1
    end

    def skip!(skipped_cols = 1)
      @current_x += skipped_cols
    end

    def append(element, **plan, &b)
      if element.is_a? BoxContainer
        @current_x += 1
        @current_y = 0 if @current_y < 0
        @fit_grid.add(element, @current_x, @current_y, arrange: false)
        # r = new_rectangle color: '#444444', border: 1
        # r.fill @fit_grid[@current_x, @current_y]
        # care r
        care element
        if block_given? && element.is_a?(Arena)
          self.class.push_build_stack element do
            element.build(&b)
          end
        end
        return element
      else
        box! gap: @gap do |bx|
          bx.append(element, **plan, &b)
        end
      end
    end

    def border=(border)
      if border.is_a? Array
        case border.size
        when 1
          @outer_border << border[0]
          @horizontal_border << border[0]
          @vertical_border << border[0]
        when 2
          @outer_border << border[0]
          @horizontal_border << border[1]
          @vertical_border << border[1]
        when 3
          @outer_border << border[0]
          @horizontal_border << border[1]
          @vertical_border << border[2]
        else
          raise "Invalid border array size #{border}"
        end
      else
        @outer_border << 0
        @horizontal_border << border
        @vertical_border << 0
      end
    end
  end
end
