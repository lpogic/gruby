# frozen_string_literal: true

# Ruby2D::Text

module Ruby2D
  # Text string drawn using the specified font and size
  class Text
    include Renderable

    pot_accessor :x, :y, :text, :size
    attr_accessor :rotate

    # Create a text string
    # @param text The text to show
    # @param [Numeric] size The font +size+
    # @param [String] font Path to font file to use to draw the text
    # @param [String] style Font style
    # @param [Numeric] x
    # @param [Numeric] y
    # @param [Numeric] z
    # @param [Numeric] rotate Angle, default is 0
    # @param [Numeric] color or +colour+ Colour the text when rendering
    # @param [Numeric] opacity Opacity of the image when rendering
    def initialize(text, size: 20, style: nil, font: Font.default,
                   x: 0, y: 0, rotate: 0, color: nil, colour: nil,
                   left: nil, right: nil, top: nil, bottom: nil)
      @x = pot x
      @y = pot y
      self.left = left if left
      self.right = right if right
      self.top = top if top
      self.bottom = bottom if bottom
      @text = pot text.to_s
      @size = pot size
      @rotate = rotate
      @style = style
      self.color = color || colour || 'white'
      @font_path = font

      @texture = nil
      @width = pot
      @height = pot
      create_font
      create_texture

      pot(@size){create_font}
      pot(@size, @text){create_texture}
    end

    # Returns the path of the font as a string
    def font
      @font_path
    end

    pot_getter :width, :height, :left, :right, :top, :bottom

    def left=(left)
      @x.let(left){_1 + width / 2}
    end

    def left_pot
      @left ||= locked_pot(@x, @width){_1 - _2 / 2}
    end

    def right=(right)
      @x.let(right){_1 - width / 2}
    end

    def right_pot
      @right ||= locked_pot(@x, @width){_1 + _2 / 2}
    end

    def top=(top)
      @y.let(top){_1 + height / 2}
    end

    def top_pot
      @top ||= locked_pot(@y, @height){_1 - _2 / 2}
    end

    def bottom=(bottom)
      @y.let(bottom){_1 - height / 2}
    end

    def bottom_pot
      @bottom ||= locked_pot(@y, @height){_1 + _2 / 2}
    end

    def draw(x:, y:, color:, rotate:)
      Window.render_ready_check

      x ||= @rotate
      color ||= [1.0, 1.0, 1.0, 1.0]

      render(x: x, y: y, color: Color.new(color), rotate: rotate)
    end

    def render(x: @x.get, y: @y.get, color: @color, rotate: @rotate)
      w = @width.get
      h = @height.get
      vertices = Vertices.new(x - w / 2, y - h / 2, w, h, rotate)
      @texture.draw(
        vertices.coordinates, vertices.texture_coordinates, color
      )
    end

    private

    def create_font
      @font = Font.load(@font_path, @size.get, @style)
    end

    def create_texture
      @texture&.delete
      @texture = Texture.new(*Text.ext_load_text(@font.ttf_font, @text.get))
      @width.set @texture.width
      @height.set @texture.height
    end
  end
end
