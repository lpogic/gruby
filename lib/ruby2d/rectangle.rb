# frozen_string_literal: true

# Ruby2D::Rectangle

module Ruby2D
  # A rectangle
  class Rectangle < Line
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
      @rect_width = width
      @rect_height = height
      d = (width - height) / 2
      if d < 0
        super(x1: x, y1: y - d,
          x2: x, y2: y + d,
          z: z, width: height, round: round, border: border, 
          color: color, colour: colour, border_color: border_color, opacity: opacity)  
      else
        super(x1: x - d, y1: y,
          x2: x + d, y2: y,
          z: z, width: width, round: round, border: border,
          color: color, colour: colour, border_color: border_color, opacity: opacity)
      end
    end

    def x() = (@x1 + @x2) / 2

    def x=(x)
      d = (@rect_width - @rect_height) / 2
      if d < 0
        @x1 = @x2 = x
      else
        @x1 = x - d
        @x2 = x + d
      end
    end

    def y() = (@y1 + @y2) / 2

    def y=(y)
      d = (@rect_width - @rect_height) / 2
      if d < 0
        @y1 = y - d
        @y2 = y + d
      else
        @y1 = @y2 = y
      end
    end

    def width() = @rect_width

    def width=(width)
      return if @rect_width == width
      x = (@x1 + @x2) / 2
      y = (@y1 + @y2) / 2
      @rect_width = width
      d = (@rect_width - @rect_height) / 2
      if d < 0
        @x1 = @x2 = x
        @y1 = y - d
        @y2 = y + d
        @width = @rect_height
      else
        @y1 = @y2 = y
        @x1 = x - d
        @x2 = x + d
        @width = @rect_width
      end
    end

    def height() = @rect_height

    def height=(height)
      return if @rect_height == height
      x = (@x1 + @x2) / 2
      y = (@y1 + @y2) / 2
      @rect_height = height
      d = (@rect_width - @rect_height) / 2
      if d < 0
        @x1 = @x2 = x
        @y1 = y - d
        @y2 = y + d
        @width = @rect_height
      else
        @y1 = @y2 = y
        @x1 = x - d
        @x2 = x + d
        @width = @rect_width
      end
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
      (@x1 + @x2 - x * 2).abs < @rect_width && (@y1 + @y2 - y * 2).abs < @rect_height
    end

    private :length
  end
end
