# frozen_string_literal: true

# Ruby2D::Circle

module Ruby2D
  #
  # Create a circle using +Circle.new+
  #
  class Circle
    include Renderable
    include Planned

    def initialize(b: nil, border: nil, sectors: 30,
                   color: 'yellow', border_color: 'black', plan: true, **na)
      @x = pot 200
      @y = pot 200
      @radius = pot 100
      @border = pot.let border || b || 0
      @sectors = sectors
      @color = cpot { Color.new _1 } << color
      @border_color = cpot { Color.new _1 } << border_color
      plan(**na) if plan
    end

    attr_accessor :sectors

    cvs_reader :x, :y, :color, :border_color, :radius, :border

    # Check if the circle contains the point at +(x, y)+
    def contains?(x, y)
      (x - @x.get)**2 + (y - @y.get)**2 <= @radius.get**2
    end

    def render
      self.class.ext_draw([
                            @x.get, @y.get, @radius.get, @border.get, @sectors,
                            *@color.get, *@border_color.get
                          ])
    end

    def default_plan(x: nil, y: nil, radius: nil, left: nil, right: nil, top: nil, bottom: nil, **)
      if radius and left
        let(radius, left).sum >> @x
      elsif radius and right
        let(radius, right){_2 - _1} >> @x
      elsif x and left
        let(x, left){_1 - _2} >> @radius
        x >> @x
      elsif x and right
        let(x, right){_2 - _1} >> @radius
        x >> @x
      elsif left and right
        let(left, right){[_2 - _1, (_2 + _1) * 0.5]} >> [@radius, @x]
      elsif x
        x >> @x
      end

      if radius and top
        let(radius, top).sum >> @y
      elsif radius and bottom
        let(radius, bottom){_2 - _1} >> @y
      elsif y and top
        let(y, top){_1 - _2} >> @radius
        y >> @y
      elsif y and bottom
        let(y, bottom){_2 - _1} >> @radius
        y >> @y
      elsif top and bottom
        let(top, bottom){[_2 - _1, (_2 + _1) * 0.5]} >> [@radius, @y]
      elsif y
        y >> @y
      end

      if radius
        radius >> @radius
      end
    end
  end
end
