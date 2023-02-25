module Ruby2D
  module Arena
    @@build_stack = []

    def self.build_stack_init(w)
      @@build_stack = [w]
    end

    def append(element, **plan, &b)
      plan[:x] = x unless Rectangle.x_dim? plan
      plan[:y] = y unless Rectangle.y_dim? plan
      element.plan(**plan.except(:width, :height))
      plan width: element.width, height: element.height
      care element
      if block_given? && element.is_a?(Arena)
        @@build_stack.push element
        element.build(&b)
        @@build_stack.pop
      end
      element
    end

    def build
      r = yield self
      text r if r.is_a? String
    end

    def plan(**a)
    end

    def method_missing(m, *a, build_stack_index: nil, **na, &b)
      r = @@build_stack.reverse.find{_1.respond_to? m}
      if r
        r.send(m, *a, **na, &b)
      else
        super
      end
    end

    def send_current(m, *a, **na, &b)
      r = @@build_stack.reverse.find{_1.respond_to? m}
      return r == self ? false : r.send(m, *a, **na, &b)
    end

    def text(t, **na)
      send_current(__method__, t, **na) || append(new_note(text: t, outfit: "text", **na.except(:x, :y, :width, :height)), **na)
    end

    def rect(**na)
      send_current(__method__, **na) || append(new_rectangle(**na.except(:x, :y, :width, :height)), **na)
    end

    def circle(**na)
      send_current(__method__, **na) || append(new_circle(**na.except(:x, :y, :width, :height)), **na)
    end

    def note(**na)
      send_current(__method__, **na) || append(new_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def ruby_note(**na)
      send_current(__method__, **na) || append(new_ruby_note(**na.except(:x, :y, :width, :height)), **na)
    end

    def album(options = [], **na)
      send_current(__method__, options, **na) || append(new_album(options: options, **na.except(:x, :y, :width, :height)), **na)
    end

    def button(t = "Button", **na)
      send_current(__method__, t, **na) || append(new_button(text: t, **na.except(:x, :y, :width, :height)), **na)
    end

    def cols(height = nil, **na, &)
      na[:height] = height if height
      send_current(__method__, **na, &) || append(Row.new(self, **na), **na, &)
    end

    def rows(width = nil, **na, &)
      na[:width] = width if width
      send_current(__method__, **na, &) || append(Col.new(self, **na), **na, &)
    end

    def form(**na, &)
      send_current(__method__, **na, &) || append(Form.new(self, **na), **na, &)
    end
  end
end
