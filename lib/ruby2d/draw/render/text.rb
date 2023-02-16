# frozen_string_literal: true

# Ruby2D::Text

module Ruby2D
  # Text string drawn using the specified font and size
  class Text
    include Renderable
    include Planned

    cvs_reader :left, :right, :top, :bottom, :x, :y, :text, :size, :color, :width, :height, :font
    attr_accessor :rotate

    def initialize(text, size: 20, style: nil, font: nil, rotate: 0, color: nil, **na)
      @x = pot 0
      @y = pot 0
      @text = compot { _1.to_s }.let(text)
      @size = pot.let size
      @rotate = rotate
      @color = compot { Color.new _1 }.let(color || 'white')
      @font_style = pot.let style
      @font = compot(@size, @font_style) { Font.load(Font.path(_3), _1, _2) }.let(font || Font.default)

      @texture_offset_x = pot 0
      @texture_offset_y = pot 0
      @texture = pot
      @texture.let(@text, @font) { create_texture(_1, _2, @texture.get) }
      @width = pot.let @texture.as { _1.width }
      @height = pot.let @texture.as { _1.height }
      plan(**na)
    end

    def default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil)
      if x
        @x.let x
      elsif left
        let(left, width) { _1 + _2 * 0.5 } >> @x
      elsif right
        let(right, width) { _1 - _2 * 0.5 } >> @x
      end

      if y
        @y.let y
      elsif top
        let(top, height) { _1 + _2 * 0.5 } >> @y
      elsif bottom
        let(bottom, height) { _1 - _2 * 0.5 } >> @y
      end
    end

    def cvs_left
      let(@x, @width) { _1 - _2 * 0.5 }
    end

    def cvs_right
      let(@x, @width) { _1 + _2 * 0.5 }
    end

    def cvs_top
      let(@y, @height) { _1 - _2 * 0.5 }
    end

    def cvs_bottom
      let(@y, @height) { _1 + _2 * 0.5 }
    end

    def render(x: @x.get, y: @y.get, color: @color.get, rotate: @rotate)
      txtr = @texture.get
      tw = txtr.width
      th = txtr.height
      tox = @texture_offset_x.get
      toy = @texture_offset_y.get
      w = @width.get
      h = @height.get
      crop = {
        image_width: tw,
        image_height: th,
        width: w,
        height: txtr.height,
        x: tw / 2 - w / 2 + tox,
        y: th / 2 - txtr.height / 2 + toy
      }
      vertices = Vertices.new((x - w / 2).floor, (y + h / 2 - txtr.height).floor, w, txtr.height, rotate)
      @texture.get.draw(
        vertices.coordinates, vertices.texture_coordinates, color
      )
    end

    def contains?(x, y)
      (self.x.get - x).abs * 2 < width.get && (self.y.get - y).abs * 2 < height.get
    end

    private

      def create_texture(text, font, texture)
        texture&.delete
        Texture.new(*Text.ext_load_text(font.ttf_font, text))
      end
  end
end
