# frozen_string_literal: true

# Ruby2D::Line

module Ruby2D
  # A line between two points.
  class Line
    include Renderable
    include Planned


    class FloatVector4

      def initialize v
        @value = case v
        when Numeric
          Array.new(4, (v / 2).round * 2)
        when Array
          if v.size == 4
            v.map{(_1 / 2).round * 2}
          else
            raise "Invalid size of #{v}"
          end
        when FloatVector4
          v.value
        else
          raise "Invalid value #{v}" 
        end
      end

      def value = @value
      def to_a = @value
    end

    def initialize(x1: 0, y1: 0, x2: 100, y2: 100,
                   thick: nil, round: nil, border: nil,
                   color: 'white', border_color: 'black')
      @x1 = pot x1
      @y1 = pot y1
      @x2 = pot x2
      @y2 = pot y2
      @thick = pot.let thick || 6
      @round = cpot { FloatVector4.new _1 } << (round || 0)
      @border = pot.let border || 0
      @color = cpot { Color.new _1 } << color
      @border_color = cpot { Color.new _1 } << border_color
    end

    cvs_reader :x1, :x2, :y1, :y2, :color, :border_color, :thick, :round, :border

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

    def render
      thick = @thick.get
      r = @round.get.to_a.map{_1.clamp(0, thick.abs)}
      b = @border.get.clamp(0, thick.abs / 2)
      self.class.ext_draw([
                            @x1.get, @y1.get, @x2.get, @y2.get, @thick.get, b, 
                            *r, *@color.get, *@border_color.get
                          ])
    end

    private

      # Calculate the distance between two points
      def points_distance(x1, y1, x2, y2)
        Math.sqrt((x1 - x2).abs2 + (y1 - y2).abs2)
      end
  end
end
