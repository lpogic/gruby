# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line
    pot_accessor :x, :y, width: [:width, :w], height: [:height, :h]
    def initialize(x: nil, y: nil, w: nil, width: nil, h: nil, height: nil,
                   r: nil, round: nil, b: nil, border: nil, 
                   color: 'white', border_color: 'black',
                   left: nil, right: nil, top: nil, bottom: nil)
      super(r: r, round: round, b: b, border: border, color: color, border_color: border_color)
      @width = pot(width || w || 200)
      @height = pot(height || h || 100)
      @x = pot(x || 200)
      @y = pot(y || 100)
      self.left = left if left
      self.right = right if right
      self.top = top if top
      self.bottom = bottom if bottom
      let(@x, @y, @width, @height) do |x, y, w, h|
        d = w - h
        d < 0 ? [x, y - d / 2, x, y + d / 2, w] : [x - d / 2, y, x + d / 2, y, h]
      end >> [@x1, @y1, @x2, @y2, @thick]
    end

    pot_getter :left, :right, :top, :bottom

    def left=(left)
      @x.let(left){_1 + width / 2}
    end

    def left_pot
      @left ||= locked_pot(@x, @rect_width){_1 - _2 / 2}
    end

    def right=(right)
      @x.let(right){_1 - width / 2}
    end

    def right_pot
      @right ||= locked_pot(@x, @rect_width){_1 + _2 / 2}
    end

    def top=(top)
      @y.let(top){_1 + height / 2}
    end

    def top_pot
      @top ||= locked_pot(@y, @rect_height){_1 - _2 / 2}
    end

    def bottom=(bottom)
      @y.let(bottom){_1 - height / 2}
    end

    def bottom_pot
      @bottom ||= locked_pot(@y, @rect_height){_1 + _2 / 2}
    end

    def self.draw(x:, y:, width:, height:, round:, border:, color:, border_color:)
      d = (width.get - height.get) / 2
      if d < 0
        super(x1: x, y1: y - d,
          x2: x, y2: y + d,
          z: z, width: height, round: round, border: border, color: color, border_color: border_color)  
      else
        super(x1: x - d, y1: y,
          x2: x + d, y2: y,
          z: z, width: width, round: round, border: border, color: color, border_color: border_color,)
      end
    end

    def contains?(x, y)
      (self.x.get - x).abs * 2 < width.get && (self.y.get - y).abs * 2 < height.get
    end

    private :length
  end
end
