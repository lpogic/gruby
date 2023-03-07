require_relative "builder_scope"

module Ruby2D
  class Arena < Cluster
    extend BuilderScope

    def append(element, **plan, &b)
      plan[:x] = x unless Rectangle.x_dim? plan
      plan[:y] = y unless Rectangle.y_dim? plan
      element.plan(**plan.except(:width, :height))
      plan width: element.width, height: element.height
      care element
      if block_given? && element.is_a?(Arena)
        self.class.push_build_stack element do
          element.build(&b)
        end
      end
      element
    end

    def build
      r = yield self
      text r if r.is_a? String
    end

    def plan(**a)
    end

    def method_missing(m, *a, **na, &b)
      sc = self.class.send_current m
      if sc
        sc.send(m, *a, **na, &b)
      else
        super
      end
    end

    def respond_method_missing? m
      !self.class.send_current(m).nil?
    end

    def text(t, **na)
      append(new_note(text: t, outfit: "text", **na.except(:x, :y, :width, :height)), **na)
    end

    def rect(**na)
      append(new_rectangle(**na.except(:x, :y, :width, :height)), **na)
    end

    def circle(**na)
      append(new_circle(**na.except(:x, :y, :width, :height)), **na)
    end

    def note(**na)
      append(new_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def ruby_note(**na)
      append(new_ruby_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def album(options = [], **na)
      append(new_album(options: options, **na.except(:x, :y, :width, :height)), **na)
    end

    def button(t = "Button", **na)
      append(new_button(text: t, **na.except(:x, :y, :width, :height)), **na)
    end

    def cols(height = nil, **na, &)
      na[:height] = height if height
      append(Row.new(self, **na), **na, &)
    end

    def rows(width = nil, **na, &b)
      na[:width] = width if width
      append(Col.new(self, **na), **na, &b)
    end

    def box(width = nil, height = nil, **na, &)
      na[:width] = width if width
      na[:height] = height if height
      append(BoxContainer.new(self, **na), **na, &)
    end

    def form(**na, &)
      append(Form.new(self, **na), **na, &)
    end

    def table(**na, &)
      append(Table.new(self, **na), **na, &)
    end

    builder_method :text, :rect, :circle, :note, :ruby_note, :album, :button,
      :cols, :rows, :box, :form, :table
  end
end
