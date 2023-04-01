module Ruby2D
  class NoteSupport < Cluster
    OpitonSelectedEvent = Struct.new(:index, :button)

    class OptionButtonBox < Cluster
      include Planned

      def init
        @width = pot 0
        @grid = Grid.new(cols: [@width])
        @buttons = []
        disable :accept_keyboard

        on :mouse_scroll do |e|
          if e.delta_y > 0
            parent.hover_down
          elsif e.delta_y < 0
            parent.hover_up
          end
        end
      end

      def set_options(options, offset, visible_options_limit)
        @objects << options[offset, visible_options_limit].each_with_index.map do |o, i|
          if @buttons[i]
            b = @buttons[i]
          else
            b = @buttons[i] = new_option_button
            b.disable :accept_keyboard
            b.on :click do
              emit :option_selected, OpitonSelectedEvent.new(i, b)
            end
            on b.hovered do |h|
              unhover b if h
            end
            @grid.rows.set { (_1 || []) + [b.height] }
            s = @grid.sector(-1, @grid.rows.get.length - 1)
            b.plan left: s.left, y: s.y, width: @width
          end
          b.text << o
          b
        end
      end

      def unhover(button_omited)
        @buttons.each do |b|
          b.hovered << false if b != button_omited
        end
      end

      def hover_down
        if @keyboard_pressed
          return true
        else
          btns = @objects.get
          if btns.size > 0
            i = btns.index { _1.hovered.get } || 0
            if i < btns.size - 1
              btns[i + 1].hovered << true
              return true
            end
          end
          return false
        end
      end

      def hover_up
        if @keyboard_pressed
          return true
        else
          btns = @objects.get
          if btns.size > 0
            i = btns.index { _1.hovered.get } || 0
            if i > 0
              btns[i - 1].hovered << true
              return true
            end
          end
          return false
        end
      end

      def press_hovered
        @keyboard_pressed = true
        btns = @objects.get
        if btns.size > 0
          i = btns.index { _1.hovered.get }
          btns[i].keyboard_pressed << true if i
        end
      end

      def release_pressed
        btns = @objects.get
        if btns.size > 0
          i = btns.index { _1.keyboard_pressed.get }
          if i
            btn = btns[i]
            btn.keyboard_pressed << false
            btn.emit :click if not btn.pressed.get
          end
        end
        @keyboard_pressed = false
      end

      delegate grid: %w[x y top bottom left right width]
      cvsa :height

      def cvs_height
        @objects.as { _1.map { |o| o.height.get }.sum }
      end

      def contains?(x, y)
        x.between?(@grid.left.get, @grid.right.get) && y.between?(@grid.top.get, @grid.bottom.get)
      end

      def default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil, width: nil)
        if x and width
          @grid.plan x: x
          @width << width
        elsif x and left
          let(x, left) { [_2, (_1 - _2) * 2] } >> [@grid.left, @width]
        elsif x and right
          let(x, right) { [_1 * 2 - _2, (_2 - _1) * 2] } >> [@grid.left, @width]
        elsif width and left
          @width << width
          @grid.left << left
        elsif width and right
          let(width, right) { [_2 - _1, _2] } >> [@grid.left, @width]
        elsif left and right
          let(left, right) { [_1, _2 - _1] } >> [@grid.left, @width]
        elsif x
          @grid.plan(:x) << x
        elsif width
          @width << width
        elsif left
          @grid.left << left
        elsif right
          let(@width, right) { _2 - _1 } >> @grid.left
        end

        if y
          @grid.plan y: y
        elsif top
          @grid.plan top: top
        elsif bottom
          @grid.plan bottom: bottom
        end
      end
    end

    class ScrollBox < Cluster
      def init
        @car = new_rect color: '#66666688'
        @rail = new_rect color: '#00000033'
        @car.plan width: @rail.width, x: @rail.x, top: @rail.top
        care @rail, @car
        @enabled = pot true
        disable :accept_keyboard
        on :mouse_down do |e|
          oy = e.y - @car.top.get
          set_bar_suppress
          rt = @rail.top.get
          rh = @rail.height.get
          ch = @car.height.get
          oy = @car.contains?(e.x, e.y) ? e.y - @car.top.get : ch / 2
          l = let(window.mouse_y, sublet_enabled: true) do |my|
            t = (my - oy).clamp(rt, rt + rh - ch)
            [t, (t - rt) / (rh - ch)]
          end >> @car.plan(:top) + [parent._scroll_box_mouse_offset]
          mu = window.on :mouse_up do
            set_bar_suppress false
            l.cancel
            mu.cancel
          end
        end
      end

      cvsa :enabled
      delegate rail: %w[x y top bottom left right width height plan contains?]

      def render
        super if @enabled.get
      end

      def accept_mouse(*)
        super if @enabled.get
      end

      def set_bar_suppress suppress = true
        @set_bar_suppress = suppress
      end

      def set_bar(total, offset, length)
        return if @set_bar_suppress

        let(@rail.height, @rail.top) do |rh, rt|
          h = rh * length / total
          [rt + (rh - h) * offset / (total - length), h]
        end >> @car.plan(:top, :height)
      end
    end

    def init
      @box = new_rect color: Color.new('#2c2c2f')
      @subject = nil
      @options = OptionButtonBox.new self
      @options.plan x: @box.x, width: @box.width
      @scroll = ScrollBox.new self
      @scroll.plan right: @box.right, width: 20, top: @options.top, height: @options.height
      @suggestions = arrpot
      @options_limit = pot 5
      @suggestions_offset = cpot(@suggestions, @options_limit) { _3.clamp(0, [_1.size - _2, 0].max) } << 0
      @scroll_box_mouse_offset = cpot(@suggestions, @options_limit) { (_1.size - _2) * _3 } << 0
      @offset = pot << let_recent(@suggestions_offset, @scroll_box_mouse_offset)
      let(@suggestions, @offset, @options_limit, sublet_enabled: true) do |sg, off, ol|
        @options.set_options sg, [off, [sg.size - ol, 0].max].min, ol
        if sg.size > ol
          @scroll.set_bar sg.size, off, ol
          @scroll.enabled << true
        else
          @scroll.enabled << false
        end
      end >> pull
      @enabled = pot false
      care @box, @options, @scroll
      @options.on :option_selected do |e|
        @on_option_selected.(@suggestions.get[@offset.get + e.index]) if @on_option_selected
      end
    end

    cvsa :suggestions, :offset, :enabled
    def options = @options

    def accept_subject(subject)
      leave @subject if @subject
      if subject
        care(@subject = subject, nanny: true)
        @box.plan x: subject.x, width: subject.width
        let(@options.height, subject.y, subject.height, subject.round) do |obh, sy, sh, sr|
          r = [4, sr.to_a.max * 0.5].max
          [sy + sh * 0.5, sy + (obh + r) * 0.5, sh + obh + r]
        end >> @options.plan(:top) + @box.plan(:y, :height)
        @box.round << subject.round
        @suggestions_offset << 0
        @enabled.set true
      else
        @subject = nil
        @enabled.set false
      end
    end

    def _scroll_box_mouse_offset
      @scroll_box_mouse_offset
    end

    def subject
      @subject
    end

    def on_option_selected(&b)
      @on_option_selected = b
    end

    def render
      super if @enabled.get
    end

    def accept_mouse(*)
      super if @enabled.get
    end

    def hover_up
      if not @options.hover_up
        off = @offset.get
        @suggestions_offset.val = off - 1 if off > 0
      end
    end

    def hover_down
      if not @options.hover_down
        off = @offset.get
        @suggestions_offset.val = off + 1 if off + @options_limit.get < @suggestions.get.size
      end
    end

    delegate box: %w[x y width height left right top bottom contains?],
             options: %w[pass_keyboard press_hovered release_pressed]
  end
end
