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

    cvs_reader :object
  end

  class BasicAlbumOutfit < NoteOutfit
    def_struct(
      :background_color,
      :background_color_hovered,
      :text_color,
      :text_color_pressed,
      :text_color_object_absent,
      :text_color_pressed_object_absent,
      :text_font,
      :text_font_object_absent,
      :text_size,
      :border_color,
      :border_color_keyboard_current,
      accessors: true
    )

    def color(c = nil, hc = nil, color: @background_color, hovered: @background_color_hovered)
      c = c || color || "#3c3c3f"
      ch = ch || hovered || "#4c4c4f"
      let_if @seed.hovered, ch, c
    end

    def text_color(c = nil, cp = nil, coa = nil, cpoa = nil, color: @text_color, pressed: @text_color_pressed,
      object_absent: @text_color_object_absent, pressed_object_absent: @text_color_pressed_object_absent)
      c = c || color || "white"
      cp = cp || pressed || "#DFDFDF"
      coa = coa || object_absent || "#AAAA11"
      cpoa = cpoa || pressed_object_absent || "#9A9A11"
      let(@seed.pressed, @seed.object, c, cp, coa, cpoa) do
        if _1
          _2 ? _4 : _6
        else
          _2 ? _3 : _5
        end
      end
    end

    def border_color(c = nil, ckc = nil, color: @border_color, keyboard_current: @border_color_keyboard_current)
      c = c || color || 0
      ckc = ckc || keyboard_current || "#7b00ae"
      let_if @seed.keyboard_current, ckc, c
    end

    def border(b = nil, border: nil)
      b || border || let_if(@seed.keyboard_current, 1, 0)
    end

    def text_font(f = nil, foa = nil, font: @text_font, object_absent: @text_font_object_absent)
      f = f || font || "consola"
      foa = foa || object_absent || "consolai"
      let_if @seed.object, f, foa
    end

    def text_size(ts = nil, text_size: @text_size)
      ts || text_size || 16
    end

    def height(h = nil, height: nil)
      h || height || @seed.text_object.height { _1 + 10 }
    end

    def width(w = nil, width: nil)
      w || width || 200
    end

    def round(r = nil, round: nil)
      r || round || 12
    end

    def width_pad(wp = nil, width_pad: nil)
      wp || width_pad || 20
    end

    def editable(e = nil, editable: nil)
      if e.nil?
        editable.nil? ? true : editable
      else
        e
      end
    end
  end
end
