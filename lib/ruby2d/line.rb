# frozen_string_literal: true

# Ruby2D::Line

module Ruby2D
  # A line between two points.
  class Line
    include Renderable

    attr_accessor :x1, :x2, :y1, :y2, :width, :round

    # Create an Line
    # @param [Numeric] x1
    # @param [Numeric] y1
    # @param [Numeric] x2
    # @param [Numeric] y2
    # @param [Numeric] width The +width+ or thickness of the line
    # @param [Numeric] z
    # @param [String, Array] color
    # @param [Numeric] opacity Opacity of the image when rendering
    # @raise [ArgumentError] if an array of colours does not have 4 entries
    def initialize(x1: 0, y1: 0, x2: 100, y2: 100, z: 0,
                   width: 6, round: 2, color: nil, colour: nil, opacity: nil)
      @x1 = x1
      @y1 = y1
      @x2 = x2
      @y2 = y2
      @z = z
      @width = width
      @round = round
      self.color = color || colour || 'white'
      self.color.opacity = opacity unless opacity.nil?
      add
    end

    # Change the colour of the line
    # @param [String, Array] color
    def color=(color)
      # convert to Color or Color::Set
      color = Color.set(color)

      @color = color
    end

    # Return the length of the line
    def length
      points_distance(@x1, @y1, @x2, @y2)
    end

    # Line contains a point if the point is closer than the length of line from
    # both ends and if the distance from point to line is smaller than half of
    # the width. For reference:
    #   https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    def contains?(x, y)
      line_len = length
      points_distance(@x1, @y1, x, y) <= line_len &&
        points_distance(@x2, @y2, x, y) <= line_len &&
        (((@y2 - @y1) * x - (@x2 - @x1) * y + @x2 * @y1 - @y2 * @x1).abs / line_len) <= 0.5 * @width
    end

    # Draw a line without creating a Line
    # @param [Numeric] x1
    # @param [Numeric] y1
    # @param [Numeric] x2
    # @param [Numeric] y2
    # @param [Numeric] width The +width+ or thickness of the line
    # @param [Numeric] round The roundness of the line
    # @param [Color] color
    def self.draw(x1:, y1:, x2:, y2:, width:, round:, color:)
      Window.render_ready_check

      ext_draw([
                 x1, y1, x2, y2, width, round, *color
               ])
    end

    private

    def render
      self.class.ext_draw([
                            @x1, @y1, @x2, @y2, @width, @round, *@color
                          ])
    end

    # Calculate the distance between two points
    def points_distance(x1, y1, x2, y2)
      Math.sqrt((x1 - x2).abs2 + (y1 - y2).abs2)
    end
  end
end
