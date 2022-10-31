# frozen_string_literal: true

# Ruby2D::Renderable

module Ruby2D
  # Base class for all renderable shapes
  module Renderable
    include CommunicatingVesselSystem

    # Add a contains method stub
    def contains?(x, y)
      x >= @x && x <= (@x + @width) && y >= @y && y <= (@y + @height)
    end
  end
end
