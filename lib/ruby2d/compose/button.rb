module Ruby2D
  class Button < Widget
    cvs_reader :keyboard_pressed

    alias mouse_pressed pressed

    def pressed
      let(mouse_pressed, keyboard_pressed).or
    end

    def init(text: nil, **na, &on_click)
      @keyboard_pressed = pot false
      @box = new_rectangle **na
      @text = new_text text, x: @box.x, y: @box.y
      care @box, @text

      on :click, &on_click if block_given?

      on :key_down do |e|
        @keyboard_pressed.set true if e.key == 'space'
      end

      on @keyboard_current do |kc|
        @keyboard_pressed.set false
      end

      on :key_up do |e|
        if e.key == 'space'
          if @keyboard_pressed.get
            @keyboard_pressed.set false
            emit :click if not pressed.get
          end
        end
      end
    end

    delegate box: %w[x y left top right bottom width height color border_color border round plan fill contains?]
    delegate text: %w(text size:text_size color:text_color x:text_x)

    def text_object = @text
  end

  class BasicButtonStyle
    include CommunicatingVesselSystem

    hash_init :element, :color, :color_hovered, :color_pressed, :text_color, :text_color_pressed, :border_color

    def text_size
      14
    end

    def border
      1
    end

    def round
      12
    end

    def color
      let @element.hovered, @element.pressed do |h, pr|
        if pr
          @color_pressed
        elsif h
          @color_hovered
        else
          @color
        end
      end
    end

    def border_color
      let @element.keyboard_current, @border_color do |kc, bc|
        kc ? Color.new('#7b00ae') : bc
      end
    end

    def text_color
      let @element.pressed do |pr|
        if pr
          @text_color_pressed
        else
          @text_color
        end
      end
    end

    def width
      @element.text_object.width.as { _1 + 20 }
    end

    def height
      @element.text_object.height.as { _1 + 10 }
    end

    def text_x
    end
  end

  class OptionButtonStyle
    include CommunicatingVesselSystem

    hash_init :element, :color, :color_hovered, :color_pressed, :text_color, :text_color_pressed, :border_color

    def text_size
      14
    end

    def border
      1
    end

    def round
      0
    end

    def color
      let @element.hovered, @element.pressed do |h, pr|
        if pr
          @color_pressed
        elsif h
          @color_hovered
        else
          @color
        end
      end
    end

    def border_color
      @border_color
    end

    def text_color
      let @element.pressed do |pr|
        if pr
          @text_color_pressed
        else
          @text_color
        end
      end
    end

    def width
      100
    end

    def height
      @element.text_object.height.as { _1 + 10 }
    end

    def text_x
      @element.text_object.plan x: let(@element.left, @element.text_object.width, 10) { _1 + _2 * 0.5 + _3 }
      class << @element
        def cancel_tab_pass_keyboard
          @tab_pass_keyboard.cancel
          @tab_pass_keyboard = nil
        end

        def pass_keyboard(*)
          false
        end
      end
      @element.cancel_tab_pass_keyboard
    end
  end
end
