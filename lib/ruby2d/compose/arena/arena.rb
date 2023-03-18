module Ruby2D
  class Arena < Cluster

    def append(element, **plan)
      plan[:x] = x unless Rectangle.x_dim? plan
      plan[:y] = y unless Rectangle.y_dim? plan
      element.plan(**plan)
      plan width: element.width, height: element.height
      care element
      element
    end

    def plan(**a)
    end
  
    def text!(t, **na)
      append(new_note(text: t, outfit: "text", **na.except(:x, :y, :width, :height)), **na)
    end

    def rect!(**na)
      append(new_rectangle(**na.except(:x, :y, :width, :height)), **na)
    end

    def circle!(**na)
      append(new_circle(**na.except(:x, :y, :width, :height)), **na)
    end

    def note!(**na)
      append(new_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def ruby_note!(**na)
      append(new_ruby_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def album!(options = [], **na)
      append(new_album(options: options, **na.except(:x, :y, :width, :height)), **na)
    end

    def button!(t = "Button", **na, &b)
      BlockScope.top append(new_button(text: t, **na.except(:x, :y, :width, :height)), **na), &b
    end

    def cols!(height = nil, **na)
      na[:height] = height if height
      append(Row.new(self, **na), **na)
    end

    def rows!(width = nil, **na)
      na[:width] = width if width
      append(Col.new(self, **na), **na)
    end

    def box!(width = nil, height = nil, **na)
      na[:width] = width if width
      na[:height] = height if height
      append(BoxContainer.new(self, **na), **na)
    end

    def form!(**na)
      append(Form.new(self, **na), **na)
    end

    def table!(**na)
      append(Table.new(self, **na), **na)
    end
  end
end
