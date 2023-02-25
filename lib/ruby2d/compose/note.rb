module Ruby2D
  class Note < Widget
    class Selection
      def initialize(start = 0, length = 0)
        @start = start
        @length = length
      end

      attr_reader :start, :length

      def empty?
        @length <= 0
      end

      def end
        @start + @length
      end

      def move(start_offset, length_offset)
        Selection.new @start + start_offset, @length + length_offset
      end

      def range
        @start...self.end
      end

      def ==(other)
        start == other.start && length == other.length
      end
    end

    class Pen < Cluster
      def init(text)
        super()
        @enabled = pot false
        @text = text
        @position = compot(@text.text { _1.length }) { _1.clamp(0, _2) }.set 0
        @rect = new_rectangle border: 0, round: 0, color: [0, 0, 0, 0.5],
          y: text.y, height: text.size, width: 2,
          left: let(@position, @text.left, @text.text) { |pos, l, t|
                  (pos <= 0) ? l : l + text.font.get.size(t[0, pos])[:width]
                }
      end

      cvs_reader :enabled, :position

      def render
        @rect.render if @enabled.get
      end
    end

    class Car < Cluster
      def init(text)
        super()
        @enabled = pot false
        @text = text
        @tl = @text.text { _1.length }
        @coordinates = pot Selection.new
        @rect = new_rectangle border: 0, round: 0, color: "#16720b", y: text.y, height: text.size
        let(@coordinates, @text.left, @text.text, @text.font) do |c, tl, t, f|
          if c.start < 0
            s = 0
            l = (c.length + c.start).clamp(0, t.length)
          else
            s = c.start
            l = [c.length, t.length - s].min
          end
          if (l > 0) && (s < t.length) && (s + l <= t.length)
            w = f.size(t[s, l])[:width]
            lw = f.size(t[0, s + l])[:width]
            [tl + lw - w, w]
          else
            [0, 0]
          end
        end >> @rect.plan(:left, :width)
      end

      cvs_reader :enabled, :coordinates

      def render
        @rect.render if @enabled.get && (@coordinates.get.length > 0)
      end
    end

    class Ring < Array
      def initialize(limit)
        @limit = limit
      end

      def push(*o)
        super
        shift(size - @limit) if size > @limit
      end
    end

    def init(text: "", **narg)
      super()
      @editable = pot true
      @width_pad = pot 20
      @box = new_rectangle(**narg)
      @text_value = compot { _1.to_s.encode("utf-8") } << text

      @text = new_text "", left: let(@box.left, @width_pad) { _1 + (_2 / 2) }, y: @box.y
      @text_offset = pot 0
      @text.text << let(@text_value, @box.width, @text_offset, @width_pad,
        @text.font) do |tv, bw, to, wp, tf|
        t = tv[to..]
        t ? t[0, tf.measure(t, bw - wp)[:count]] : ""
      end
      @pen_position = compot(@text_value.as { _1.length }) do |tvl, v|
        v.clamp(0, tvl)
      end << 0
      @pen = Pen.new self, @text
      @pen.enabled.let(@keyboard_current, @editable) { _1 & _2 }
      @selection = pot Selection.new
      @car = Car.new self, @text
      @car.enabled << @keyboard_current
      @car.coordinates << let(@selection, @text_offset) { _1.move(-_2, 0) }
      @story = Ring.new 50
      @story_index = 0

      care @box, @car, @text, @pen

      on @keyboard_current do |kc|
        enable_text_input kc
      end

      on @pen_position do |pp, _ppp|
        to = @text_offset.get
        if pp - to < 0
          @text_offset.set(pp)
          @pen.position << 0
        else
          tl = @text.text.get.length
          if to + tl < pp
            @text_offset.set(pp - tl)
            @pen.position << tl
          else
            @pen.position << (pp - to)
          end
        end
        @selection.set Selection.new(pp) if @selection.get.empty?
      end

      on_key do |e|
        case e.key
        when "left"
          pen_left(shift_down, if ctrl_down
            alt_down ? :class : :word
          else
            :character
                               end)
        when "right"
          pen_right(shift_down, if ctrl_down
            alt_down ? :class : :word
          else
            :character
                                end)
        when "backspace"
          if @editable.get
            if @selection.get.empty?
              pen_erase(:left)
            else
              paste ""
            end
          end
        when "delete"
          if @editable.get
            if @selection.get.empty?
              pen_erase(:right)
            else
              paste ""
            end
          end
        when "home"
          pen_left(shift_down, @pen_position.get)
        when "keypad 7"
          pen_left(shift_down, @pen_position.get) if !num_locked
        when "end"
          pen_right(shift_down, @text_value.get.length - @pen_position.get)
        when "keypad 1"
          pen_right(shift_down, @text_value.get.length - @pen_position.get) if !num_locked
        when "a"
          select_all if ctrl_down
        when "v"
          paste clipboard if ctrl_down
        when "c"
          if ctrl_down
            text = get_selected
            self.clipboard = text if text != ""
          end
        when "x"
          if ctrl_down
            selection = @selection.get
            if !selection.empty?
              c = shift_down ? clipboard : ""
              self.clipboard = @text_value.get[selection.range]
              paste c
            elsif shift_down
              paste clipboard
            end
          end
        when "z"
          if ctrl_down
            if shift_down
              story_front
            else
              story_back
            end
          end
        end
      end

      on :key_text do |e|
        txt = e.text
        txt.upcase! if shift_down
        paste txt, true
      end

      @mouse_pen = pot false

      on :mouse_down do |e|
        case e.button
        when :left
          @mouse_pen.set true
          tt = @text.text.get
          x = @text.font.get.nearest(tt, e.x - @box.left.get - (@width_pad.get / 2))
          pen_at x + @text_offset.get, shift_down
          mmh = window.on :mouse_move do |e|
            tl = @text.left.get
            if tl > e.x
              pen_left true if e.delta_x < 0
            elsif @text.right.get < e.x
              pen_right true if e.delta_x > 0
            else
              x = @text.font.get.nearest(tt, e.x - @box.left.get - (@width_pad.get / 2))
              pen_at x + @text_offset.get, true
            end
          end
          window.on :mouse_up do |_ue, muh|
            @mouse_pen.set false
            muh.cancel
            mmh.cancel
          end
        when :middle
          @pen.enabled = false
          mmh = window.on :mouse_move do |e|
            if e.delta_x < 0
              to = @text_offset.get
              @text_offset.set(to + 1) if to + @text.text.get.length < @text_value.get.length
            elsif e.delta_x > 0
              to = @text_offset.get
              @text_offset.set(to - 1) if to > 0
            end
          end
          window.on :mouse_up do |_ue, muh|
            @pen.enabled = @keyboard_current
            @pen_position.set { _1 }
            muh.cancel
            mmh.cancel
          end
        end
      end

      on :mouse_scroll do |e|
        if e.delta_x < 0 || (e.delta_x == 0 && e.delta_y < 0)
          pen_left(shift_down, if ctrl_down
            alt_down ? :class : :word
          else
            :character
                               end)
        elsif e.delta_x > 0 || (e.delta_x == 0 && e.delta_y > 0)
          pen_right(shift_down, if ctrl_down
            alt_down ? :class : :word
          else
            :character
                                end)
        end
      end

      on :double_click do |e|
        if e.button == :left
          if @text.right.get >= e.x
            tt = @text.text.get
            to = @text_offset.get
            tv = @text_value.get
            x = @text.font.get.nearest(tt, e.x - @box.left.get - (@width_pad.get / 2), bound: :gap)
            sl = class_step_left tv, to + x, :character_class
            sr = class_step_right tv, to + x, :character_class
            @selection.set Selection.new(to + x - sl, sl + sr + 1)
          end
        end
      end

      on :triple_click do |e|
        select_all if e.button == :left
      end
    end

    def inspect
      "#{self.class} text:\"#{@text_value.get}\""
    end

    delegate box: %w[fill plan x y left top right bottom width height color border_color border round]
    delegate text: %w[text:text_visible font:text_font size:text_size color:text_color]
    cvs_reader %w[text_value:text width_pad pen_position editable text_offset keyboard_current]

    def text_object = @text

    def text_offset=(to)
      @text_offset.let(to, @text_value.as { _1.length }) { _1.clamp(0, _2) }
    end

    def contains?(x, y)
      @box.contains?(x, y)
    end

    def pass_keyboard(current, reverse: false)
      return false unless @editable.get

      super
    end

    def pen_at(position, selection = false)
      pp = @pen_position.get
      if pp < position
        pen_right(selection, position - pp)
      elsif pp > position
        pen_left(selection, pp - position)
      elsif !selection
        @selection.set(Selection.new(pp))
      end
    end

    def pen_left(selection = false, step = :character)
      pp = @pen_position.get
      st = case step
      when Integer then step
      when :character then 1
      when :class then class_step_left(@text_value.get, pp - 1) + 1
      when :word then word_step_left(@text_value.get, pp - 1) + 1
      end
      if selection
        if pp > 0
          s = @selection.get
          if s.length > 0
            if pp == s.start
              @selection.set(s.move(-st, st))
            elsif pp == s.end
              if st <= s.length
                @selection.set(s.move(0, -st))
              else
                @selection.set(Selection.new(s.end - st, st - s.length))
              end
            else
              @selection.set(Selection.new(pp - st, st))
            end
          else
            @selection.set(Selection.new(pp - st, st))
          end
        end
      else
        @selection.set(Selection.new)
      end

      @pen_position.set(pp - st)
    end

    def pen_right(selection = false, step = :character)
      pp = @pen_position.get
      st = case step
      when Integer then step
      when :character then 1
      when :class then class_step_right(@text_value.get, pp) + 1
      when :word then word_step_right(@text_value.get, pp) + 1
      end
      if selection
        if pp < @text_value.get.length
          s = @selection.get
          if s.length > 0
            if pp == s.start
              if st <= s.length
                @selection.set(s.move(st, -st))
              else
                @selection.set(Selection.new(s.end, st - s.length))
              end
            elsif pp == s.end
              @selection.set(s.move(0, st))
            else
              @selection.set(Selection.new(pp, st))
            end
          else
            @selection.set(Selection.new(pp, st))
          end
        end
      else
        @selection.set(Selection.new)
      end

      @pen_position.set(pp + st)
    end

    def pen_erase(direction = :right)
      pp = @pen_position.get
      tv = @text_value.get
      if direction == :right
        @text_value.set(tv[0, pp] + tv[pp + 1..]) if pp < tv.length
      elsif pp > 0
        @text_value.set(tv[0, pp - 1] + tv[pp..])
        @pen_position.set(pp - 1)
      end
    end

    def select_all
      tvl = @text_value.get.length
      @selection.set(Selection.new(0, tvl))
      @pen_position.set tvl
    end

    def get_selected
      selection = @selection.get
      selection.empty? ? "" : @text_value.get[selection.range]
    end

    def paste(str, type = false)
      return unless @editable.get

      selection = @selection.get
      tv = @text_value.get
      if type
        if @type_story
          if (@type_story[:start] + @type_story[:length] == @pen_position.get) && selection.empty?
            @type_story[:length] += 1
          else
            close_type_story
            @type_story = {
              start: selection.start,
              length: 1,
              text: tv,
              start_selection: selection
            }
          end
        else
          @type_story = {
            start: selection.start,
            length: 1,
            text: tv,
            start_selection: selection
          }
        end
      elsif @type_story
        close_type_story
      end
      if selection.empty?
        pp = @pen_position.get
        @text_value.set(tv[...pp] + str + tv[pp..])
        @pen_position.set(pp + str.length)
      else
        ntv = tv[...selection.start] + str + tv[selection.end..]
        @text_value.set(ntv)
        @pen_position.set(0)
        pen_at selection.start + str.length
        @selection.set(Selection.new(@pen_position.get))
      end
      story_push(selection, tv, Selection.new(selection.start)) if !type && @text_value != tv
    end

    class PasteStoryEntry
      def initialize(back_select, text, front_select)
        @back_select = back_select
        @text = text
        @front_select = front_select
      end

      attr_accessor :front_select, :back_select

      def back(text, selection, pen_position)
        if selection.get == @back_select || (@back_select.empty? && pen_position.get == front_select.end)
          text.set @text
          selection.set Selection.new
          pen_position.set @front_select.end
          true
        else
          selection.set @back_select
          pen_position.set @back_select.end
          false
        end
      end

      def front(text, selection, pen_position, prev_entry)
        front_select = prev_entry.front_select
        back_select = prev_entry.back_select
        if selection.get == front_select || (front_select.empty? && pen_position.get == front_select.end)
          text.set @text
          selection.set Selection.new
          pen_position.set back_select.end
          true
        else
          selection.set front_select
          pen_position.set front_select.end
          false
        end
      end
    end

    def close_type_story
      story_push(Selection.new(@type_story[:start], @type_story[:length]), @type_story[:text],
        @type_story[:start_selection])
      @type_story = nil
    end

    def story_push(selection_in_new_text, old_text, selection_in_old_text)
      @story.pop(@story.size - @story_index) if @story.size > @story_index
      @story.push(PasteStoryEntry.new(selection_in_new_text, old_text, selection_in_old_text))
      @story_index = @story.size
    end

    def story_back
      close_type_story if @type_story
      return unless @story_index > 0

      if @story.size == @story_index
        @story.push(PasteStoryEntry.new(@selection.get, @text_value.get,
          Selection.new))
      end
      return unless @story[@story_index - 1].back(@text_value, @selection, @pen_position)

      @story_index -= 1
    end

    def story_front
      if @story_index + 1 < @story.size && @story[@story_index + 1].front(@text_value, @selection, @pen_position,
        @story[@story_index])
        @story_index += 1
      end
    end

    class SupportPack
      def initialize(note, options, filter)
        @events = []
        show_option_buttons_box = proc do
          ns = note.window.note_support
          if ns.subject != note
            ns.accept_subject note
            ns.suggestions << let(options, note.text) do |op, txt|
              [op.filter(&filter.curry[txt])]
            end
            ns.on_option_selected do |o|
              note.select_all
              note.paste o.to_s
              note.select_all
              ns.accept_subject nil
            end
          end
        end
        @events << note.on(note.keyboard_current) do |kc|
          note.window.note_support.accept_subject nil unless kc
        end
        @events << note.on(:click) do
          show_option_buttons_box.call
        end
        @events << note.on(:double_click) do
          show_option_buttons_box.call
          if note.get_selected == ""
            note.select_all
            note.paste ""
          end
        end
        @events << note.on_key do |e|
          if e.key == "down" || e.key == "up"
            show_option_buttons_box.call
            ns = note.window.note_support
            ns.hover_down if e.key == "down"
            ns.hover_up if e.key == "up"
          end
        end
        @events << note.on(:key_down) do |e|
          ns = note.window.note_support
          ns.press_hovered if e.key == "return" && (ns.subject == note)
        end
        @events << note.on(:key_up) do |e|
          ns = note.window.note_support
          ns.release_pressed if e.key == "return" && (ns.subject == note)
        end
      end

      def cancel
        @events.each { _1.cancel }
        @events = []
      end
    end

    def support(options, filter: :default)
      @support&.cancel
      filter = case filter
      when :include_nocase
        proc { |txt, item| item.to_s.downcase.include? txt.downcase }
      when :include
        proc { |txt, item| item.to_s.include? txt }
      when :start_with_nocase
        proc { |txt, item| item.to_s.downcase.start_with? txt.downcase }
      when :match, :regexp
        proc { |txt, item| item.to_s.match? txt }
      when :include_nocase_match, :default
        proc do |txt, item|
          str = item.to_s
          begin
            str.downcase.include? txt.downcase or str.match? txt
          rescue RegexpError
            false
          end
        end
      else
        filter.to_proc
      end
      @support = SupportPack.new self, options, filter
    end

    private

    def class_step_right(text, start, classifier = :strict_character_class)
      return 0 if start + 1 >= text.length

      cc = send(classifier, text[start])
      text[start + 1..].each_char.take_while { send(classifier, _1) == cc }.count
    end

    def word_step_right(text, start)
      return 0 if start + 1 >= text.length

      cc = character_class(text[start]) == :blank
      cnt = text[start + 1..].each_char.take_while { (character_class(_1) == :blank) == cc }.count
      cnt += text[start + cnt + 1..].each_char.take_while { character_class(_1) == :blank }.count if character_class(text[start + cnt + 1]) == :blank
      cnt
    end

    def class_step_left(text, start, classifier = :strict_character_class)
      return 0 if start <= 0

      cc = send(classifier, text[start])
      text[..start - 1].reverse.each_char.take_while { send(classifier, _1) == cc }.count
    end

    def word_step_left(text, start)
      return 0 if start <= 0

      cc = character_class(text[start]) == :blank
      cnt = text[..start - 1].reverse.each_char.take_while { (character_class(_1) == :blank) == cc }.count
      cnt += text[..start - cnt - 1].reverse.each_char.take_while { character_class(_1) == :blank }.count if character_class(text[start - cnt - 1]) == :blank
      cnt
    end

    def strict_character_class(ch)
      case ch
      when /\p{Ll}/ then :loweralpha
      when /\p{Lu}/ then :upperalpha
      when /\p{Nd}/ then :digit
      when /\p{Blank}/ then :blank
      else :other
      end
    end

    def character_class(ch)
      case ch
      when /[\p{L}_]/ then :alpha
      when /\p{Nd}/ then :digit
      when /\p{Blank}/ then :blank
      else :other
      end
    end
  end

  class NoteOutfit < Outfit
    def hatch
      if @seed
        @seed.color << color
        @seed.border_color << border_color
        @seed.text_color << text_color
        @seed.border << border
        @seed.round << round
        @seed.width_pad << width_pad
        @seed.text_size << text_size
        @seed.text_font << text_font
        @seed.editable << editable
        @seed
      end
    end
  end

  class BasicNoteOutfit < NoteOutfit
    def_struct(
      :background_color,
      :background_color_hovered,
      :text_color,
      :text_color_pressed,
      :text_font,
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

    def text_color(c = nil, cp = nil, color: @text_color, pressed: @text_color_pressed)
      c = c || color || "white"
      cp = cp || pressed || "#DFDFDF"
      let_if @seed.pressed, cp, c
    end

    def border_color(c = nil, ckc = nil, color: @border_color, keyboard_current: @border_color_keyboard_current)
      c = c || color || 0
      ckc = ckc || keyboard_current || "#7b00ae"
      let_if @seed.keyboard_current, ckc, c
    end

    def border(b = nil, border: nil)
      b || border || let_if(@seed.keyboard_current, 1, 0)
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

  class TextNoteOutfit < NoteOutfit
    def_struct(
      :background_color,
      :text_color,
      :text_font,
      :text_size,
      accessors: true
    )

    def color(c = nil, color: @background_color)
      c || color || [0, 0, 0, 0]
    end

    def text_color(c = nil, color: @text_color)
      c || color || "white"
    end

    def border_color(c = nil, color: @border_color)
      c || color || [0, 0, 0, 0]
    end

    def border(b = nil, border: nil)
      b || border || 0
    end

    def text_font(tf = nil, text_font: @text_font)
      tf || text_font || "rubik-regular"
    end

    def text_size(ts = nil, text_size: @text_size)
      ts || text_size || 14
    end

    def height(h = nil, height: nil)
      h || height || @seed.text_object.height { _1 + 3 }
    end

    def width(w = nil, width: nil)
      w || width || let(@seed.text_font, @seed.text) { _1.size(_2)[:width] + 1 }
    end

    def round(r = nil, round: nil)
      r || round || 0
    end

    def width_pad(wp = nil, width_pad: nil)
      wp || width_pad || 0
    end

    def editable(e = nil, editable: nil)
      if e.nil?
        editable.nil? ? false : editable
      else
        e
      end
    end
  end
end
