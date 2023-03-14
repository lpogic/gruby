module Ruby2D
  class Button < Widget

    def init(text: nil, **na, &on_click)
      @keyboard_pressed = pot false
      @box = new_rectangle(**na)
      @text = new_text text, x: @box.x, y: @box.y
      care @box, @text

      on :click, &on_click if on_click

      on :key_down do |e|
        @keyboard_pressed.set true if e.key == "space"
      end

      on @keyboard_current do |_kc|
        @keyboard_pressed.set false
      end

      on :key_up do |e|
        if e.key == "space" && @keyboard_pressed.get
          @keyboard_pressed.set false
          emit :click unless pressed.get
        end
      end
    end

    masking do

      cvsa :keyboard_pressed

      alias_method :mouse_pressed, :pressed

      def pressed
        let(mouse_pressed, keyboard_pressed).or
      end

      delegate box: %w[x y left top right bottom width height color border_color border round plan fill contains?]
      delegate text: %w[text size:text_size color:text_color x:text_x font:text_font]

      def text_object = @text

    end#masking
  end

  class ButtonOutfit < Outfit
    def hatch
      if @seed
        @seed.color << color
        @seed.border_color << border_color
        @seed.text_color << text_color
        @seed.border << border
        @seed.round << round
        @seed.text_size << text_size
        @seed.text_font << text_font
        @seed
      end
    end
  end

  class BasicButtonOutfit < ButtonOutfit
    def_struct(
      :background_color,
      :background_color_hovered,
      :background_color_pressed,
      :text_color,
      :text_color_pressed,
      :text_font,
      :text_size,
      :border_color,
      :border_color_keyboard_current,
      accessors: true
    )

    def color(c = nil, hc = nil, color: @background_color, hovered: @background_color_hovered, pressed: @background_color_pressed)
      c = c || color || "blue"
      ch = ch || hovered || "#1084E9"
      cp = cp || pressed || "#0064C9"
      let(@seed.hovered, @seed.pressed, c, ch, cp) do
        if _2
          _5
        elsif _1
          _4
        else
          _3
        end
      end
    end

    def text_color(c = nil, pc = nil, color: @text_color, pressed: @text_color_pressed)
      c = c || color || "white"
      cp = cp || pressed || "#DFDFDF"
      let_if @seed.pressed, cp, c
    end

    def border_color(c = nil, ckc = nil, color: @border_color, keyboard_current: @border_color_keyboard_current)
      c = c || color || "blue"
      ckc = ckc || keyboard_current || "#7b00ae"
      let_if @seed.keyboard_current, ckc, c
    end

    def border(b = nil, border: nil)
      b || border || 1
    end

    def text_font(tf = nil, text_font: @text_font)
      tf || text_font || "consola"
    end

    def text_size(ts = nil, text_size: @text_size)
      ts || text_size || 16
    end

    def height(h = nil, height: nil)
      h || height || @seed.text_object.height { _1 + 10 }
    end

    def width(w = nil, width: nil)
      w || width || @seed.text_object.width { _1 + 20 }
    end

    def round(r = nil, round: nil)
      r || round || 12
    end
  end

  class OptionButtonOutfit < ButtonOutfit
    def_struct(
      :background_color,
      :background_color_hovered,
      :background_color_pressed,
      :text_color,
      :text_color_pressed,
      :text_font,
      :text_size,
      :border_color,
      :border_color_keyboard_current,
      accessors: true
    )

    def hatch
      super
      if @seed
        @seed.text_object.plan x: let(@seed.left, @seed.text_object.width, 10) { _1 + (_2 * 0.5) + _3 }
        class << @seed
          def cancel_tab_pass_keyboard
            @tab_pass_keyboard.cancel
            @tab_pass_keyboard = nil
          end

          def pass_keyboard(*)
            false
          end
        end
        @seed.cancel_tab_pass_keyboard
      end
    end

    def color(c = nil, hc = nil, color: @background_color, hovered: @background_color_hovered, pressed: @background_color_pressed)
      c = c || color || "#2c2c2f"
      ch = ch || hovered || "#4c4c4f"
      cp = cp || pressed || "#5c5c5f"
      let(@seed.hovered, @seed.pressed, c, ch, cp) do
        if _2
          _5
        elsif _1
          _4
        else
          _3
        end
      end
    end

    def text_color(c = nil, pc = nil, color: @text_color, pressed: @text_color_pressed)
      c = c || color || "white"
      cp = cp || pressed || "#DFDFDF"
      let_if @seed.pressed, cp, c
    end

    def border_color(c = nil, ckc = nil, color: @border_color, keyboard_current: @border_color_keyboard_current)
      c = c || color || "#2c2c2f"
      ckc = ckc || keyboard_current || "#7b00ae"
      let_if @seed.keyboard_current, ckc, c
    end

    def border(b = nil, border: nil)
      b || border || 1
    end

    def text_font(tf = nil, text_font: @text_font)
      tf || text_font || "consola"
    end

    def text_size(ts = nil, text_size: @text_size)
      ts || text_size || 16
    end

    def height(h = nil, height: nil)
      h || height || @seed.text_object.height { _1 + 10 }
    end

    def width(w = nil, width: nil)
      w || width || 100
    end

    def round(r = nil, round: nil)
      r || round || 0
    end
  end
end
