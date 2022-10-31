# frozen_string_literal: true

# Ruby2D::Circle

module Ruby2D
  #
  # Create a circle using +Circle.new+
  #
  class Circle
    include Renderable

    def initialize(x: 25, y: 25, r: nil, radius: nil, b: nil, border: nil, sectors: 30,
                   color: 'yellow', border_color: 'black')
      @x = pot x
      @y = pot y
      @radius = pot(radius || r || 100)
      @border = pot(border || b || 0)
      @sectors = sectors
      @color = compot{Color.new _1}.let color
      @border_color = compot{Color.new _1}.let border_color
    end

    attr_accessor :sectors
    cvs_accessor :x, :y, :color, :border_color
    cvs_accessor [:radius, :r] => :radius, [:border, :b] => :border

    # Check if the circle contains the point at +(x, y)+
    def contains?(x, y)
      (x - @x.get) ** 2 + (y - @y.get) ** 2 <= @radius.get ** 2
    end

    def self.draw(opts = {})
      Window.render_ready_check

      ext_draw([
                 opts[:x], opts[:y], opts[:radius], opts[:border], opts[:sectors],
                 opts[:color][0], opts[:color][1], opts[:color][2], opts[:color][3],
                 opts[:border_color][0], opts[:border_color][1], opts[:border_color][2], opts[:border_color][3],
               ])
    end

    def render
      self.class.ext_draw([
                            @x.get, @y.get, @radius.get, @border.get, @sectors,
                            *@color.get, *@border_color.get
                          ])
    end
  end
end
