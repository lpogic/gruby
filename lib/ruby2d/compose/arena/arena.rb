module Ruby2D
  class Arena < Cluster

    def append(element, **plan)
      plan[:x] = x unless Rectangle.x_dim? plan
      plan[:y] = y unless Rectangle.y_dim? plan
      element.plan(**plan)
      plan width: element.width, height: element.height
      care element
      element
    end

    builder :cols do |height = nil, **plan|
      plan[:height] = height if height
      e = Row.new(self, **plan)
    end

    builder :rows do |width = nil, **plan|
      plan[:width] = width if width
      e = Col.new(self, **plan)
    end

    builder :box do |width = nil, height = nil, **plan|
      plan[:width] = width if width
      plan[:height] = height if height
      e = BoxContainer.new(self, **plan)
    end

    builder :form do |**plan|
      e = Form.new(self, **plan)
    end

    builder :table do |**plan|
      e = Table.new(self, **plan)
    end
  end
end
