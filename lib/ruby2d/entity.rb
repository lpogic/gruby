# frozen_string_literal: true

# Ruby2D::Entity

module Ruby2D
  # Any object that can be managed by a Ruby2D::Window must be an Entity
  module Entity
    include CommunicatingVesselsSystem
    
    def emit(type, event = nil)  
    end

    def contains?(x, y)
      false
    end
  end
end
