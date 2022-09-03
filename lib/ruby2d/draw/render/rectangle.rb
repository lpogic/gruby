# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line
    pot_accessor :x, :y, [:width, :w] => :width, [:height, :h] => :height
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

    pot_accessor :left, :right, :top, :bottom, :hbounds, :vbounds

    def _left
      @left ||= let(@x, @width){_1 - _2 / 2}.affect{|left| @x.let(left, @width){_1 + _2 / 2}}
    end

    def _right
      @right ||= let(@x, @width){_1 + _2 / 2}.affect{|right| @x.let(right, @width){_1 - _2 / 2}}
    end

    def _top
      @top ||= let(@y, @height){_1 - _2 / 2}.affect{|top| @y.let(top, @height){_1 + _2 / 2}}
    end

    def _bottom
      @bottom ||= let(@y, @height){_1 + _2 / 2}.affect{|bottom| @y.let(bottom, @height){_1 - _2 / 2}}
    end

    class HBounds
      def initialize(left, right)
        @left = left
        @right = right
      end

      attr_reader :left, :right

      def self.make(hb)
        case hb
        when Hbounds then hb
        when Hash then Hbounds.new(hb[:left], hb[:right])
        else raise "Error"
        end
      end
    end

    def _hbounds
      @hbounds ||= let(@x, @width) do |x, w|
        HBounds.new(x - w / 2, x + w / 2)
      end.affect do |hb|
        let(hb){hb = HBounds.make(_1); [(hb.left + hb.right) / 2, hb.right - hb.left]} >> [@x, @width]
      end
    end

    class VBounds
      def initialize(top, bottom)
        @top = top
        @bottom = bottom
      end

      attr_reader :top, :bottom

      def self.make(hb)
        case hb
        when Hbounds then hb
        when Hash then Vbounds.new(hb[:top], hb[:bottom])
        else raise "Error"
        end
      end
    end

    def _vbounds
      @vbounds ||= let(@y, @height) do |y, h|
        VBounds.new(top: y - h / 2, bottom: y + h / 2)
      end.affect do |vb|
        let(vb){vb = VBounds.make(_1); [(vb.top + vb.bottom) / 2, vb.bottom - vb.top]} >> [@y, @height]
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
