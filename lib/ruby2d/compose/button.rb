module Ruby2D
  class Button < Widget

    def init(text: nil, **na)
      super()
      @keyboard_pressed = pot false
      @box = new_rect
      @text = new_raw_text text, x: @box.x, y: @box.y
      care @box, @text

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

    cvsa :keyboard_pressed

    alias_method :mouse_pressed, :pressed

    def pressed
      let(mouse_pressed, keyboard_pressed).or
    end

    delegate box: %w[x y left top right bottom width height color border_color border round fill contains?]
    delegate text: %w[text size:text_size color:text_color x:text_x font:text_font]

    def raw_text = @text

    def border_color_plan(border_color_rest: nil, border_color_keyboard_current: nil, **)
      if border_color_keyboard_current and border_color_rest
        border_color << case_let(keyboard_current, border_color_keyboard_current, border_color_rest)
      end
    end
      
    def default_plan(
      color_rest: nil, color_hovered: nil, color_pressed: nil, 
      border_color_rest: nil, border_color_keyboard_current: nil,
      text_color_rest: nil, text_color_pressed: nil,
      border: nil, round: nil, text_size: nil, text_font: nil,
      **na)
      @box.plan **na.slice(:x, :y, :width, :height, :right, :left, :top, :bottom)
      if color_rest and color_hovered and color_pressed
        color << case_let(pressed, color_pressed, hovered, color_hovered, color_rest)
      end
      border_color_plan **na
      if text_color_pressed and text_color_rest
        text_color << case_let(pressed, text_color_pressed, text_color_rest)
      end
      if border
        self.border << border
      end
      if round
        self.round << round
      end
      if text_size
        self.text_size << text_size
      end
      if text_font
        self.text_font << text_font
      end
    end
  end
end
