# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line
    let_accessor :x, :y, rect_width: 'width', rect_height: 'height'
    # Create an rectangle
    # @param [Numeric] x
    # @param [Numeric] y
    # @param [Numeric] width
    # @param [Numeric] height
    # @param [Numeric] round
    # @param [Numeric] z
    # @param [String, Array] color
    # @param [String | Color] border_color
    # @param [Numeric] opacity Opacity of the image when rendering
    def initialize(x: 0, y: 0, width: 200, height: 100, round: 0, border: 0, z: 0, 
      color: nil, colour: nil, border_color: nil, opacity: nil)
      @rect_width = Let.new width
      @rect_height = Let.new height
      @x = Let.new x
      @y = Let.new y
      super(x1: ->{
        d = @rect_width.get - @rect_height.get
        d < 0 ? @x.get : @x.get - d / 2
      }, y1: ->{
        d = @rect_width.get - @rect_height.get
        d < 0 ? @y.get - d / 2 : @y.get
      }, x2: ->{
        d = @rect_width.get - @rect_height.get
        d < 0 ? @x.get : @x.get + d / 2
      }, y2: ->{
        d = @rect_width.get - @rect_height.get
        d < 0 ? @y.get + d / 2 : @y.get
      }, z: z, width: ->{
        [@rect_width.get, @rect_height.get].min
      }, round: round, border: border, 
        color: color, colour: colour, border_color: border_color, opacity: opacity)  
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
