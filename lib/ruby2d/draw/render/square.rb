# frozen_string_literal: true

# Ruby2D::Square

module Ruby2D
  # A square
  class Square < Rectangle
    
    def initialize(x: nil, y: nil, s: nil, size: nil,
                   r: nil, round: nil, b: nil, border: nil, 
                   color: 'white', border_color: 'black',
                   left: nil, right: nil, top: nil, bottom: nil)
      super(x: x, y: y, z: z, round: round, border: border,
            color: color, border_color: border_color, left: left, right: right, top: top, bottom: bottom)
      @size = pot(size || s || 100)
      let(@size){[_1, _1]} >> [@width, @height]
    end

    cvs_accessor [:size, :s] => :size

    def self.draw(x:, y:, size:, round:, border:, color:)
      super(x: x, y: y,
            width: size, height: size, round: round, border: border,
            color: color)
    end

    # Make the inherited width and height attribute accessors private
    private :width=, :height=
  end
end
