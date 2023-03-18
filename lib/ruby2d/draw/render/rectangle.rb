# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line

    cvsa :left, :right, :top, :bottom, :x, :y, :width, :height

    def initialize(r: nil, round: nil, b: nil, border: nil,
                   color: 'white', border_color: 'black', **na)
      super(round: round, border: border, color: color, border_color: border_color)
      @width = pot 200
      @height = pot 100
      @x = pot 200
      @y = pot 100

      let(@x, @y, @width, @height) do |x, y, w, h|
        d = w - h
        d < 0 ? [x, y - d * 0.5, x, y + d * 0.5, w] : [x - d * 0.5, y, x + d * 0.5, y, h]
      end >> [@x1, @y1, @x2, @y2, @thick]

      plan(**na)
    end

    def default_plan(x: nil, y: nil, width: nil, height: nil, left: nil, right: nil, top: nil, bottom: nil, **)
      if x and width
        @x << x
        @width << width
      elsif x and left
        let(x, left) { [_1, (_1 - _2) * 2] } >> [@x, @width]
      elsif x and right
        let(x, right) { [_1, (_2 - _1) * 2] } >> [@x, @width]
      elsif width and left
        let(width, left) { [_2 + _1 * 0.5, _1] } >> [@x, @width]
      elsif width and right
        let(width, right) { [_2 - _1 * 0.5, _1] } >> [@x, @width]
      elsif left and right
        let(left, right) { [(_1 + _2) * 0.5, _2 - _1] } >> [@x, @width]
      elsif x
        @x << x
      elsif width
        @width << width
      elsif left
        let(@width, left) { _2 + _1 * 0.5 } >> @x
      elsif right
        let(@width, right) { _2 - _1 * 0.5 } >> @x
      end

      if y and height
        @y << y
        @height << height
      elsif y and top
        let(y, top) { [_1, (_1 - _2) * 2] } >> [@y, @height]
      elsif y and bottom
        let(y, bottom) { [_1, (_2 - _1) * 2] } >> [@y, @height]
      elsif height and top
        let(height, top) { [_2 + _1 * 0.5, _1] } >> [@y, @height]
      elsif height and bottom
        let(height, bottom) { [_2 - _1 * 0.5, _1] } >> [@y, @height]
      elsif top and bottom
        let(top, bottom) { [(_1 + _2) * 0.5, _2 - _1] } >> [@y, @height]
      elsif y
        @y << y
      elsif height
        @height << height
      elsif top
        let(@height, top) { _2 + _1 * 0.5 } >> @y
      elsif bottom
        let(@height, bottom) { _2 - _1 * 0.5 } >> @y
      end
    end

    def cvs_left
      let(@x, @width) { _1 - _2 * 0.5 }
    end

    def cvs_right
      let(@x, @width) { _1 + _2 * 0.5 }
    end

    def cvs_top
      let(@y, @height) { _1 - _2 * 0.5 }
    end

    def cvs_bottom
      let(@y, @height) { _1 + _2 * 0.5 }
    end

    def contains?(x, y)
      (self.x.get - x).abs * 2 < width.get && (self.y.get - y).abs * 2 < height.get
    end

    def fill(o)
      plan x: o.x, y: o.y, width: o.width, height: o.height
    end

    def self.x_dim?(plan)
      plan.any_in?(:x, :left, :right)
    end

    def self.y_dim?(plan)
      plan.any_in? :y, :top, :bottom
    end

    def self.w_dim?(plan)
      plan[:width] || (plan.keys & %i[x left right]).size > 1
    end

    def self.h_dim?(plan)
      plan[:height] || (plan.keys & %i[y top bottom]).size > 1
    end

    private :length
  end
end
