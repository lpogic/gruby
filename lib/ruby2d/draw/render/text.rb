# frozen_string_literal: true

# Ruby2D::Text

module Ruby2D
  # Text string drawn using the specified font and size
  class Text
    include Renderable

    pot_accessor :x, :y, :text, :size, :color, :left, :right, :top, :bottom, 
      :width, :height, :font_path
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
    def initialize(text, size: 20, style: nil, font: nil,
                   x: 0, y: 0, rotate: 0, color: nil,
                   left: nil, right: nil, top: nil, bottom: nil)
      @x = pot x
      @y = pot y
      @text = pot text
      @size = pot size
      @rotate = rotate
      @style = style
      @color = pot_affect{Color.new _1}.let(color || 'white')
      @font_path = pot_affect{Font.path _1}.let(font || Font.default)
      @font_style = pot(style)
      @font = pot(@font_path, @size, @font_style){Font.load(_1, _2, _3)}

      @texture_offset_x = pot 0
      @texture_offset_y = pot 0
      @texture = pot
      @texture.let(@text, @font){create_texture(_1, _2, @texture.get)}
      @width = @texture.as{_1.width}.pot
      @height = @texture.as{_1.height}.pot
      self.left = left if left
      self.right = right if right
      self.top = top if top
      self.bottom = bottom if bottom
    end

    def font
      @font
    end

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


    def draw(x:, y:, color:, rotate:)
      Window.render_ready_check

      x ||= @rotate
      color ||= [1.0, 1.0, 1.0, 1.0]

      render(x: x, y: y, color: Color.new(color), rotate: rotate)
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
        height: h,
        x: tw / 2 - w / 2 + tox,
        y: th / 2 - h / 2 + toy
      }
      vertices = Vertices.new(x - w / 2, y - h / 2, w, h, rotate, crop: crop)
      @texture.get.draw(
        vertices.coordinates, vertices.texture_coordinates, color
      )
    end

    private

    def create_texture(text, font, texture)
      texture&.delete
      Texture.new(*Text.ext_load_text(font.ttf_font, text))
    end
  end
end
