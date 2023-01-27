module Ruby2D
  module Arena
    def init(*, **, &)
      super
      @_top = self
    end

    def parent=(parent)
      super
      build
    end

    def build; end

    def append(element, **plan)
      if @_top == self
        plan[:x] = x unless Rectangle.x_dim? plan
        plan[:y] = y unless Rectangle.y_dim? plan
        element.plan(**plan.except(:width, :height))
        plan width: element.width, height: element.height
        care element
      else
        @_top.append(element, **plan)
      end
      top = @_top
      @_top = element
      if block_given?
        r = yield element
        element.append(new_note(text: r, style: 'text')) if r.is_a? String
      end
      @_top = top
      element
    end

    def plan(**a); end

    def row(height = nil, **na, &)
      na[:height] = height if height
      append(Row.new(self, **na), **na, &)
    end

    def col(width = nil, **na, &)
      na[:width] = width if width
      append(Col.new(self, **na), **na, &)
    end

    def gap(size)
      append(Gap.new(size))
    end

    def text(t, **na)
      append(new_note(text: t, style: 'text', **na.except(:x, :y, :width, :height)), **na)
    end

    def note(**na)
      append(new_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def ruby_note(**na)
      append(new_ruby_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def button(t = 'Button', **na)
      append(new_button(text: t, **na.except(:x, :y, :width, :height)), **na)
    end

    def rect(**ona)
      append(new_rectangle(**ona.except(:x, :y, :width, :height)), **ona)
    end

    def circle(**ona)
      append(new_circle(**ona.except(:x, :y, :width, :height)), **ona)
    end
  end
end
