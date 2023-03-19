# frozen_string_literal: true

# Ruby2D::Entity

module Ruby2D
  module Entity
    include CVS
    attr_accessor :parent, :nanny

    def emit(type, event = nil)
    end

    def contains?(x, y)
      false
    end

    def accept_mouse(e)
      contains?(e.x, e.y) ? self : nil
    end

    def lineage
      @parent.lineage + [self]
    end

    def window = parent.window

    def up(selector = nil)
      case selector
      when Class
        parent.is_a?(selector) ? parent : parent.up(selector)
      end
    end
  end
end