# frozen_string_literal: true

# Ruby2D::Entity

module Ruby2D
  # Any object that can be managed by a Ruby2D::Window must be an Entity
  module Entity
    include CommunicatingVesselSystem
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
  end
end
