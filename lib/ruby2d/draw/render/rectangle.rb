# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line
    pot_accessor :x, :y, :left, :right, :top, :bottom, [:width, :w] => :width, [:height, :h] => :height
    def initialize(x: nil, y: nil, w: nil, width: nil, h: nil, height: nil,
                   r: nil, round: nil, b: nil, border: nil, 
                   color: 'white', border_color: 'black',
                   left: nil, right: nil, top: nil, bottom: nil)
      super(r: r, round: round, b: b, border: border, color: color, border_color: border_color)
      @width = pot(width || w || 200)
      @height = pot(height || h || 100)
      @x = pot(x || 200)
      @y = pot(y || 100)

      let(@x, @y, @width, @height) do |x, y, w, h|
        d = w - h
        d < 0 ? [x, y - d / 2, x, y + d / 2, w] : [x - d / 2, y, x + d / 2, y, h]
      end >> [@x1, @y1, @x2, @y2, @thick]

      if left or right
        plan :left, :right
        self.left = left if left
        self.right = right if right
      end
      if top or bottom
        plan :top, :bottom
        self.top = top if top
        self.bottom = bottom if bottom
      end
    end

    def plan(*params)
      if params.include?(:left)
        ensure_left_right
        if params.include?(:right)
          plan_params [:left, :right], [:x, :width] do [(_1 + _2) / 2, _2 - _1] end
        elsif params.include?(:width)
          plan_params [:left, :width], [:x, :right] do [_1 + _2 / 2, _1 + _2] end
        elsif params.include?(:x)
          plan_params [:x, :left], [:width, :right] do [(_1 - _2) * 2, _2 * 2 - _1] end
        else raise "Unsupported plan #{params}"
        end
      elsif params.include?(:right)
        ensure_left_right
        if params.include?(:width)
          plan_params [:right, :width], [:x, :left] do [_1 - _2 / 2, _1 - _2] end
        elsif params.include?(:x)
          plan_params [:right, :x], [:width, :left] do [(_1 - _2) * 2, _2 * 2 - _1] end
        else raise "Unsupported plan #{params}"
        end
      elsif params.include?(:x)
        if params.include?(:width)
          if @left
            plan_params [:x, :width], [:left, :right] do [_1 - _2 / 2, _1 + _2 / 2] end
          end
        else raise "Unsupported plan #{params}"
        end
      end

      if params.include?(:top)
        ensure_top_bottom
        if params.include?(:bottom)
          plan_params [:top, :bottom], [:y, :height] do [(_1 + _2) / 2, _2 - _1] end
        elsif params.include?(:height)
          plan_params [:top, :height], [:y, :bottom] do [_1 + _2 / 2, _1 + _2] end
        elsif params.include?(:y)
          plan_params [:y, :top], [:height, :bottom] do [(_1 - _2) * 2, _2 * 2 - _1] end
        else raise "Unsupported plan #{params}"
        end
      elsif params.include?(:bottom)
        ensure_top_bottom
        if params.include?(:height)
          plan_params [:bottom, :height], [:y, :top] do [_1 - _2 / 2, _1 - _2] end
        elsif params.include?(:y)
          plan_params [:bottom, :y], [:height, :top] do [(_1 - _2) * 2, _2 * 2 - _1] end
        else raise "Unsupported plan #{params}"
        end
      elsif params.include?(:y)
        if params.include?(:height)
          if @top
            plan_params [:y, :height], [:top, :bottom] do [_1 - _2 / 2, _1 + _2 / 2] end
          end
        else raise "Unsupported plan #{params}"
        end
      end
      params.map{instance_variable_get("@#{_1}")}
    end

    def _left
      ensure_left_right
      @left
    end

    def _right
      ensure_left_right
      @right
    end

    def ensure_left_right
      if not @left or not @right
        let(@x, @width){[_1 - _2 / 2, _1 + _2 / 2]} >> [@left = pot, @right = pot]
        @left.lock_inlet
        @right.lock_inlet
      end
    end

    def _top
      ensure_top_bottom
      @top
    end

    def _bottom
      ensure_top_bottom
      @bottom
    end

    def ensure_top_bottom
      if not @top or not @bottom
        let(@y, @height){[_1 - _2 / 2, _1 + _2 / 2]} >> [@top = pot, @bottom = pot]
        @top.lock_inlet
        @bottom.lock_inlet
      end
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
