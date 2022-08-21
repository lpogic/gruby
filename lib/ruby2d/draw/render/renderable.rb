# frozen_string_literal: true

# Ruby2D::Renderable

module Ruby2D
  # Base class for all renderable shapes
  module Renderable
    include CommunicatingVesselsSystem

    # Set the color value
    def color=(color)
      @color = Color.new(color)
    end

    # Add a contains method stub
    def contains?(x, y)
      x >= @x && x <= (@x + @width) && y >= @y && y <= (@y + @height)
    end
  end
end
