module Ruby2D
  class Album < Note
    def init options: [], **ar
      super(**ar)
      @object = pot
      @events = []
      filter = proc do |txt, item|
        str = item.to_s
        begin
          str.downcase.include? txt.downcase or str.match? txt
        rescue RegexpError
          false
        end
      end
      show_option_buttons_box = proc do
        ns = window.note_support
        if ns.subject != self
          ns.accept_subject self
          ns.suggestions << let(options, text) do |op, txt|
            op.filter(&filter.curry[txt])
          end
          ns.on_option_selected do |o|
            select_all
            paste o.to_s
            object << o
            ns.accept_subject nil
          end
        end
      end
      @events << on(keyboard_current) do |kc|
        window.note_support.accept_subject nil unless kc
      end
      @events << on(:click) do
        show_option_buttons_box.call
      end
      @events << on(:double_click) do
        show_option_buttons_box.call
        if get_selected == ""
          select_all
          paste ""
        end
      end
      @events << on_key do |e|
        if e.key == "down" || e.key == "up"
          show_option_buttons_box.call
          ns = window.note_support
          ns.hover_down if e.key == "down"
          ns.hover_up if e.key == "up"
        end
      end
      @events << on(:key_down) do |e|
        ns = window.note_support
        ns.press_hovered if e.key == "return" && (ns.subject == self)
      end
      @events << on(:key_up) do |e|
        ns = window.note_support
        ns.release_pressed if e.key == "return" && (ns.subject == self)
      end
      @events << on(text) do
        object << nil
      end
    end

    cvsa :object

    def val
      object.get
    end

    def text_color_plan(text_color_rest: nil, text_color_pressed: nil, text_color_pressed_object_absent: nil,
      text_color_rest_object_absent: nil, **)

      if text_color_pressed and text_color_rest
        if text_color_pressed_object_absent and text_color_rest_object_absent
          text_color << let(pressed, object, text_color_rest, text_color_pressed, text_color_pressed_object_absent, text_color_rest_object_absent) do
            if _1
              _2 ? _4 : _6
            else
              _2 ? _3 : _5
            end
          end
        else
          text_color << case_let(pressed, text_color_pressed, text_color_rest)
        end
      end
    end

    def text_font_plan(text_font: nil, text_font_object_absent: nil, **)
      if text_font
        if text_font_object_absent
          self.text_font << case_let(object, text_font, text_font_object_absent)
        else
          self.text_font << text_font
        end
      end
    end
  end
end
