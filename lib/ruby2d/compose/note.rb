module Ruby2D
  class Note < Widget
    class Selection
      def initialize(start = 0, length = 0)
        @start = start
        @length = length
      end

      attr_reader :start, :length

      def empty?
        return @length <= 0
      end

      def end
        return @start + @length
      end

      def move(start_offset, length_offset)
        Selection.new @start + start_offset, @length + length_offset
      end

      def range
        @start...self.end
      end

      def ==(that)
        start == that.start && length == that.length
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
                                      pos <= 0 ? l : l + text.font.get.size(t[0, pos])[:width]
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
        @rect = new_rectangle border: 0, round: 0, color: '#36921b', y: text.y, height: text.size
        let(@coordinates, @text.left, @text.text, @text.font) do |c, tl, t, f|
          if c.start < 0
            s = 0
            l = (c.length + c.start).clamp(0, t.length)
          else
            s = c.start
            l = [c.length, t.length - s].min
          end
          if l > 0 and s < t.length and s + l <= t.length
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
        @rect.render if @enabled.get and @coordinates.get.length > 0
      end
    end

    class LimitedStack < Array
      def initialize(limit)
        @limit = limit
      end

      def push(*o)
        super
        if size > @limit
          shift(size - @limit)
        end
      end
    end

    def init(text: '', **narg)
      super()
      @editable = pot true
      @width_pad = pot 20
      @box = new_rectangle **narg
      @text_value = compot { _1.to_s.encode('utf-8') } << text

      @text = new_text '', left: let(@box.left, @width_pad) { _1 + _2 / 2 }, y: @box.y
      @text_offset = pot 0
      @text.text << let(@text_value, @box.width, @text_offset, @width_pad, @text.size,
                        @text.font) do |tv, bw, to, wp, ts, tf|
        t = tv[to..]
        t ? t[0, tf.measure(t, bw - wp)[:count]] : ''
      end
      @pen_position = compot(@text_value.as { _1.length }) do |tvl, v|
        if v < 0 then 0
        elsif v > tvl then tvl
        else v
        end
      end << 0
      @pen = Pen.new self, @text
      @pen.enabled.let(@keyboard_current, @editable) { _1 & _2 }
      @selection = pot Selection.new
      @car = Car.new self, @text
      @car.enabled << @keyboard_current
      @car.coordinates << let(@selection, @text_offset) { _1.move(-_2, 0) }
      @story = LimitedStack.new 50
      @story_index = 0

      care @box, @car, @text, @pen

      on @keyboard_current do |kc|
        enable_text_input kc
      end

      on @pen_position do |pp, ppp|
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
            @pen.position << pp - to
          end
        end
        @selection.set Selection.new(pp) if @selection.get.empty?
      end

      on :key_type do |e|
        case e.key
        when 'left'
          pen_left(shift_down, ctrl_down ? alt_down ? :class : :word : :character)
        when 'right'
          pen_right(shift_down, ctrl_down ? alt_down ? :class : :word : :character)
        when 'backspace'
          if @editable.get
            if @selection.get.empty?
              pen_erase(:left)
            else
              paste ''
            end
          end
        when 'delete'
          if @editable.get
            if @selection.get.empty?
              pen_erase(:right)
            else
              paste ''
            end
          end
        when 'home'
          pen_left(shift_down, @pen_position.get)
        when 'end'
          pen_right(shift_down, @text_value.get.length - @pen_position.get)
        when 'a'
          select_all if ctrl_down
        when 'v'
          paste clipboard if ctrl_down
        when 'c'
          if ctrl_down
            selection = @selection.get
            self.clipboard = @text_value.get[selection.range] if not selection.empty?
          end
        when 'x'
          if ctrl_down
            selection = @selection.get
            if not selection.empty?
              c = shift_down ? clipboard : ''
              self.clipboard = @text_value.get[selection.range]
              paste c
            elsif shift_down
              paste clipboard
            end
          end
        when 'z'
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
          x = @text.font.get.nearest(tt, e.x - @box.left.get - @width_pad.get / 2)
          pen_at x + @text_offset.get, shift_down
          mmh = window.on :mouse_move do |e|
            tl = @text.left.get
            if tl > e.x
              pen_left true if e.delta_x < 0
            elsif @text.right.get < e.x
              pen_right true if e.delta_x > 0
            else
              x = @text.font.get.nearest(tt, e.x - @box.left.get - @width_pad.get / 2)
              pen_at x + @text_offset.get, true
            end
          end
          window.on :mouse_up do |ue, muh|
            @mouse_pen.set false
            muh.cancel
            mmh.cancel
          end
        when :middle
          @pen.enabled = false
          mmh = window.on :mouse_move do |e|
            if e.delta_x < 0
              to = @text_offset.get
              if to + @text.text.get.length < @text_value.get.length
                @text_offset.set(to + 1)
              end
            elsif e.delta_x > 0
              to = @text_offset.get
              if to > 0
                @text_offset.set(to - 1)
              end
            end
          end
          window.on :mouse_up do |ue, muh|
            @pen.enabled = @keyboard_current
            @pen_position.set { _1 }
            muh.cancel
            mmh.cancel
          end
        end
      end

      on :mouse_scroll do |e|
        if e.delta_x < 0 || e.delta_x == 0 && e.delta_y < 0
          pen_left(shift_down, ctrl_down ? alt_down ? :class : :word : :character)
        elsif e.delta_x > 0 || e.delta_x == 0 && e.delta_y > 0
          pen_right(shift_down, ctrl_down ? alt_down ? :class : :word : :character)
        end
      end

      on :double_click do |e|
        if e.button == :left
          tt = @text.text.get
          to = @text_offset.get
          x = @text.font.get.nearest(tt, e.x - @box.left.get - @width_pad.get / 2)
          sl = class_step_left @text_value.get, to + x, :character_class
          sr = class_step_right @text_value.get, to + x, :character_class
          @selection.set Selection.new(to + x - sl, sl + sr + 1)
        end
      end

      on :triple_click do |e|
        if e.button == :left
          select_all
        end
      end
    end

    def inspect
      "#{self.class} text:\"#{@text_value.get}\""
    end

    delegate box: %w(fill plan x y left top right bottom width height color border_color border round)
    delegate text: %w(text:text_visible font:text_font size:text_size color:text_color)
    cvs_reader %w(text_value:text width_pad pen_position editable text_offset keyboard_current)

    def text_object = @text

    def text_offset=(to)
      @text_offset.let(to, @text_value.as { _1.length }) { _1.clamp(0, _2) }
    end

    def contains?(x, y)
      @box.contains?(x, y)
    end

    def pass_keyboard(current, reverse: false)
      if @editable.get
        super
      else
        return false
      end
    end

    def pen_at(position, selection = false)
      pp = @pen_position.get
      if pp < position
        pen_right(selection, position - pp)
      elsif pp > position
        pen_left(selection, pp - position)
      elsif not selection
        @selection.set(Selection.new pp)
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
                @selection.set(Selection.new s.end - st, st - s.length)
              end
            else
              @selection.set(Selection.new pp - st, st)
            end
          else
            @selection.set(Selection.new pp - st, st)
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
                @selection.set(Selection.new s.end, st - s.length)
              end
            elsif pp == s.end
              @selection.set(s.move(0, st))
            else
              @selection.set(Selection.new pp, st)
            end
          else
            @selection.set(Selection.new pp, st)
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
        if pp < tv.length
          @text_value.set(tv[0, pp] + tv[pp + 1..])
        end
      else
        if pp > 0
          @text_value.set(tv[0, pp - 1] + tv[pp..])
          @pen_position.set(pp - 1)
        end
      end
    end

    def select_all
      tvl = @text_value.get.length
      @selection.set(Selection.new 0, tvl)
      @pen_position.set tvl
    end

    def paste(str, type = false)
      return if not @editable.get

      selection = @selection.get
      tv = @text_value.get
      if type
        if @type_story
          if @type_story[:start] + @type_story[:length] == @pen_position.get and selection.empty?
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
      else
        close_type_story if @type_story
        story_push(selection, tv, Selection.new(selection.start))
      end
      if selection.empty?
        pp = @pen_position.get
        @text_value.set(tv[...pp] + str + tv[pp..])
        @pen_position.set(pp + str.length)
      else
        @text_value.set(tv[...selection.start] + str + tv[selection.end..])
        @pen_position.set(selection.start + str.length)
        @selection.set(Selection.new @pen_position.get)
      end
    end

    class PasteStoryEntry
      def initialize(back_select, text, front_select)
        @back_select = back_select
        @text = text
        @front_select = front_select
      end

      attr_accessor :front_select, :back_select

      def back(text, selection, pen_position)
        if selection.get == @back_select
          text.set @text
          selection.set Selection.new
          pen_position.set @front_select.end
          return true
        else
          selection.set @back_select
          pen_position.set @back_select.end
          return false
        end
      end

      def front(text, selection, pen_position, prev_entry)
        front_select = prev_entry.front_select
        back_select = prev_entry.back_select
        if selection.get == front_select || front_select.empty? && pen_position.get == front_select.end
          text.set @text
          selection.set Selection.new
          pen_position.set back_select.end
          return true
        else
          selection.set front_select
          pen_position.set front_select.end
          return false
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
      @story.push(PasteStoryEntry.new selection_in_new_text, old_text, selection_in_old_text)
      @story_index = @story.size
    end

    def story_back
      close_type_story if @type_story
      if @story_index > 0
        @story.push(PasteStoryEntry.new @selection.get, @text_value.get,
                                        Selection.new) if @story.size == @story_index
        if @story[@story_index - 1].back(@text_value, @selection, @pen_position)
          @story_index -= 1
        end
      end
    end

    def story_front
      if @story_index + 1 < @story.size && @story[@story_index + 1].front(@text_value, @selection, @pen_position,
                                                                          @story[@story_index])
        @story_index += 1
      end
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
        if character_class(text[start + cnt + 1]) == :blank
          cnt += text[start + cnt + 1..].each_char.take_while { character_class(_1) == :blank }.count
        end
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
        if character_class(text[start - cnt - 1]) == :blank
          cnt += text[..start - cnt - 1].reverse.each_char.take_while { character_class(_1) == :blank }.count
        end
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

  class BasicNoteStyle
    include CommunicatingVesselSystem

    def initialize(element,
                   color, color_hovered, color_pressed,
                   text_color, text_color_pressed, text_font)
      @element = element
      @color = color
      @color_hovered = color_hovered
      @color_pressed = color_pressed
      @text_color = text_color
      @text_color_pressed = text_color_pressed
      @text_font = text_font
    end

    def text_size
      14
    end

    def text_font
      @text_font
    end

    def border
      let @element.keyboard_current do |kc|
        kc ? 1 : 0
      end
    end

    def round
      8
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
      let @element.keyboard_current do |kc|
        kc ? Color.new('#7b00ae') : Color.new('black')
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

    def height
      let(@element.text_object.height) { _1 + 10 }
    end

    def width_pad
      20
    end

    def width
      200
    end

    def editable
      true
    end
  end

  class TextNoteStyle
    include CommunicatingVesselSystem

    def initialize(element, color, text_color, text_font)
      @element = element
      @color = color
      @text_color = text_color
      @text_font = text_font
    end

    def text_size
      14
    end

    def text_font
      @text_font
    end

    def border
      0
    end

    def round
      0
    end

    def color
      @color
    end

    def border_color
      [0, 0, 0, 0]
    end

    def text_color
      @text_color
    end

    def height
      @element.text_object.height.as { _1 + 3 }
    end

    def width_pad
      0
    end

    def width
      let(@element.text_font, @element.text) { _1.size(_2)[:width] + 1 }
    end

    def editable
      false
    end
  end
end
