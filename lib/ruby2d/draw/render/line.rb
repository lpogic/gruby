# frozen_string_literal: true

# Ruby2D::Line

module Ruby2D
  # A line between two points.
  class Line
    include Renderable
    include Planned

    def initialize(x1: 0, y1: 0, x2: 100, y2: 100,
                   t: nil, thick: nil, r: nil, round: nil, b: nil, border: nil, 
                   color: 'white', border_color: 'black')
      @x1 = pot x1
      @y1 = pot y1
      @x2 = pot x2
      @y2 = pot y2
      @thick = pot(thick || t || 6)
      @round = pot(round || r || 0)
      @border = pot(border || b || 0)
      @color = compot{Color.new _1}.let color
      @border_color = compot{Color.new _1}.let border_color
    end

    cvs_accessor(:x1, :x2, :y1, :y2, :color, :border_color,
      [:thick, :t] => :thick, 
      [:round, :r] => :round, 
      [:border, :b] => :border
    )

    # Return the length of the line
    def length
      points_distance(@x1.get, @y1.get, @x2.get, @y2.get) + @thick.get
    end

    # Line contains a point if the point is closer than the length of line from
    # both ends and if the distance from point to line is smaller than half of
    # the thick. For reference:
    #   https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    def contains?(x, y)
      x1 = @x1.get
      x2 = @x2.get
      y1 = @y1.get
      y2 = @y2.get
      line_len = points_distance(x1, y1, x2, y2)
      points_distance(x1, y1, x, y) <= line_len &&
        points_distance(x2, y2, x, y) <= line_len &&
        (((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1).abs / line_len) <= 0.5 * @thick.get
    end

    # Draw a line without creating a Line
    # @param [Numeric] x1
    # @param [Numeric] y1
    # @param [Numeric] x2
    # @param [Numeric] y2
    # @param [Numeric] thick The +thick+ or thickness of the line
    # @param [Numeric] round The roundness of the line
    # @param [Color] color
    def self.draw(x1:, y1:, x2:, y2:, thick:, round:, border:, color:, border_color:)
      Window.render_ready_check

      ext_draw([
                 x1, y1, x2, y2, thick, round, border, *color, *border_color
               ])
    end

    def render
      self.class.ext_draw([
                            @x1.get, @y1.get, @x2.get, @y2.get, @thick.get, @round.get, @border.get, *@color.get, *@border_color.get
                          ])
    end

    private

    # Calculate the distance between two points
    def points_distance(x1, y1, x2, y2)
      Math.sqrt((x1 - x2).abs2 + (y1 - y2).abs2)
    end
  end
end
