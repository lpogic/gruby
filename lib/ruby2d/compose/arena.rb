module Ruby2D
  class Arena < Cluster
    def init
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
        plan[:x] = x unless plan_x_defined? plan
        plan[:y] = y unless plan_y_defined? plan
        element.plan(**plan)
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

    def row(height = nil, **na, &b)
      na[:height] = height if height
      append(Row.new(self, **na), **na, &b)
    end

    def col(width = nil, **na, &b)
      na[:width] = width if width
      append(Col.new(self, **na), **na, &b)
    end

    def gap(size)
      append(Gap.new(size))
    end

    def text(t, **na)
      append(new_note(text: t, style: 'text', **na), **na)
    end

    def note(**na)
      append(new_note(**na), **na)
    end

    def button(t, **na)
      append(new_button(text: t, **na), **na)
    end

    def rect(**ona)
      append(new_rectangle(**ona, plan: false), **ona)
    end

    def circle(**ona)
      append(new_circle(**ona), **ona)
    end
  end
end
