# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line
    pot_accessor :x, :y, width: :rect_width, height: :rect_height
    def initialize(**args)
      super()
      @rect_width = pot 200
      @rect_height = pot 100
      @x = pot 0
      @y = pot 0
      args.each{|k, v| send "#{k}=", v}
      let @x, @y, @rect_width, @rect_height, out: [@x1, @y1, @x2, @y2, @width] do |x, y, w, h|
        d = w - h
        d < 0 ? [x, y - d / 2, x, y + d / 2, w] : [x - d / 2, y, x + d / 2, y, h]
      end
    end

    pot_reader :left, :right, :top, :bottom

    def left=(left)
      @x.let(left){_1 + width / 2}
    end

    def left!
      @left ||= pot_view(@x, @rect_width){_1 - _2 / 2}
    end

    def right=(right)
      @x.let(right){_1 - width / 2}
    end

    def right!
      @right ||= pot_view(@x, @rect_width){_1 + _2 / 2}
    end

    def top=(top)
      @y.let(top){_1 + height / 2}
    end

    def top!
      @top ||= pot_view(@y, @rect_height){_1 - _2 / 2}
    end

    def bottom=(bottom)
      @y.let(bottom){_1 - height / 2}
    end

    def bottom!
      @bottom ||= pot_view(@y, @rect_height){_1 + _2 / 2}
    end

    def self.draw(x:, y:, width:, height:, round:, border:, color:, border_color:)
      d = (width - height) / 2
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
      (self.x - x).abs * 2 < width && (self.y - y).abs * 2 < height
    end

    private :length
  end
end
