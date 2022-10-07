# frozen_string_literal: true

# Ruby2D::Renderable

module Ruby2D
  # Base class for all renderable shapes
  module Renderable
    include CommunicatingVesselSystem

    def plan_params(i, o, &block)
      o = o.map{"@#{_1}"}.map{instance_variable_set(_1, instance_variable_get(_1) || pot)}
      i = i.map{"@#{_1}"}.map{instance_variable_set(_1, instance_variable_get(_1) || pot)}
      o.each{_1.unlock_inlet}
      let(*i, &block) >> o
      o.each{_1.lock_inlet}
      i.each{_1.unlock_inlet}
    end

    # Add a contains method stub
    def contains?(x, y)
      x >= @x && x <= (@x + @width) && y >= @y && y <= (@y + @height)
    end
  end
end
