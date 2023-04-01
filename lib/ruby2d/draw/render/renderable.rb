# frozen_string_literal: true

# Ruby2D::Renderable

module Ruby2D
  # Base class for all renderable shapes
  module Renderable
    include CVS

    # Add a contains method stub
    def contains?(x, y)
      false
    end

    def names
      []
    end

    def des(filter)
      []
    end
  end
end
