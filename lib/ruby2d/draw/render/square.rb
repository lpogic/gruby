# frozen_string_literal: true

# Ruby2D::Square

module Ruby2D
  # A square
  class Square < Rectangle
    # Create an square
    # @param [Numeric] x
    # @param [Numeric] y
    # @param [Numeric] size is width and height
    # @param [Numeric] z
    # @param [String, Array] color
    # @param [String | Color] border_color
    # @param [Numeric] opacity Opacity of the image when rendering
    def initialize(x: 0, y: 0, size: 100, z: 0, round: 0, border: 0, color: nil, colour: nil, border_color: nil, opacity: nil)
      super(x: x, y: y, width: size, height: size, z: z, round: round, border: border,
            color: color, colour: colour, border_color: border_color, opacity: opacity)
    end

    # Set the size of the square
    def size=(size)
      self.width = self.height = size
    end

    def size() = width

    def self.draw(x:, y:, size:, round:, border:, color:)
      super(x: x, y: y,
            width: size, height: size, round: round, border: border,
            color: color)
    end

    # Make the inherited width and height attribute accessors private
    private :width=, :height=
  end
end
