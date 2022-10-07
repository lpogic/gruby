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
      @color = compot{Color.new _1}.let(color || 'white')
      @font_path = compot{Font.path _1}.let(font || Font.default)
      @font_style = pot(style)
      @font = pot(@font_path, @size, @font_style){Font.load(_1, _2, _3)}

      @texture_offset_x = pot 0
      @texture_offset_y = pot 0
      @texture = pot
      @texture.let(@text, @font){create_texture(_1, _2, @texture.get)}
      @width = @texture.as{_1.width}.pot
      @height = @texture.as{_1.height}.pot
      if left or right
        plan :left, :right
        self.left = left if left
        self.right = right if right
      end
      if top or bottom
        plan :top, :bottom
        self.top = top if top
        self.bottom = bottom if bottom
      end
    end

    def font
      @font
    end

    def plan(*params)
      if params.include?(:left)
        ensure_left_right
        plan_params [:left, :width], [:x, :right] do [_1 + _2 / 2, _1 + _2] end
      elsif params.include?(:right)
        ensure_left_right
        plan_params [:right, :width], [:x, :left] do [_1 - _2 / 2, _1 - _2] end
      elsif params.include?(:x)
        if @left
          plan_params [:x, :width], [:left, :right] do [_1 - _2 / 2, _1 + _2 / 2] end
        end
      end

      if params.include?(:top)
        ensure_top_bottom
        plan_params [:top, :height], [:y, :bottom] do [_1 + _2 / 2, _1 + _2] end
      elsif params.include?(:bottom)
        ensure_top_bottom
        plan_params [:bottom, :height], [:y, :top] do [_1 - _2 / 2, _1 - _2] end
      elsif params.include?(:y)
        if @top
          plan_params [:y, :height], [:top, :bottom] do [_1 - _2 / 2, _1 + _2 / 2] end
        end
      end
      params.map{instance_variable_get("@#{_1}")}
    end


    def _left
      ensure_left_right
      @left
    end

    def _right
      ensure_left_right
      @right
    end

    def ensure_left_right
      if not @left or not @right
        let(@x, @width){[_1 - _2 / 2, _1 + _2 / 2]} >> [@left = pot, @right = pot]
        @left.lock_inlet
        @right.lock_inlet
      end
    end

    def _top
      ensure_top_bottom
      @top
    end

    def _bottom
      ensure_top_bottom
      @bottom
    end

    def ensure_top_bottom
      if not @top or not @bottom
        let(@y, @height){[_1 - _2 / 2, _1 + _2 / 2]} >> [@top = pot, @bottom = pot]
        @top.lock_inlet
        @bottom.lock_inlet
      end
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
