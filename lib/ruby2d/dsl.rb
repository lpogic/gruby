# frozen_string_literal: true

module Ruby2D
  # Ruby2D::DSL
  module DSL
    @@window = Ruby2D::Window.new
    BlockScope.push Kernel, @@window

    def method_missing(name, *a, **na, &b)
      @@window.send(name, *a, **na, &b)
    end
  end
end
