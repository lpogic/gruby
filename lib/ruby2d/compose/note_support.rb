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
          end

          def set_options(options, offset, visible_options_limit)
              @objects << options[offset, visible_options_limit].each_with_index.map do |o, i|
                if @buttons[i]
                  b = @buttons[i]
                else
                  b = @buttons[i] = new_button(style: 'option')
                  b.disable :accept_keyboard
                  b.on :click do
                    emit :option_selected, OpitonSelectedEvent.new(i, b)
                  end
                  on b.hovered do |h|
                    unhover b if h
                  end
                  @grid.rows.set{(_1 || []) + [b.height]}
                  s = @grid.sector(-1, -1)
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
            btns = @objects.get
            if btns.size > 0
              i = btns.index{_1.hovered.get}
              if !i
                btns[0].hovered << true
                return true
              elsif i < btns.size - 1
                btns[i + 1].hovered << true 
                return true
              end
            end
            return false
          end

          def hover_up
            btns = @objects.get
            if btns.size > 0
              i = btns.index{_1.hovered.get}
              if !i
                btns[0].hovered << true
                return true
              elsif i > 0
                btns[i - 1].hovered << true
                return true
              end
            end
            return false
          end

          def press_hovered
            btns = @objects.get
            if btns.size > 0
              i = btns.index{_1.hovered.get}
              btns[i].keyboard_pressed << true if i
            end
          end

          def release_pressed
            btns = @objects.get
            if btns.size > 0
              i = btns.index{_1.keyboard_pressed.get}
              if i
                btn = btns[i]
                btn.keyboard_pressed << false
                btn.emit :click if not btn.pressed.get
              end
            end
          end

          delegate grid: %w[x y top bottom left right width]
          cvs_reader :height

          def _cvs_height
            @objects.as{_1.map{|o| o.height.get}.sum}
          end

          def contains?(x, y)
            x.between?(@grid.left.get, @grid.right.get) && y.between?(@grid.top.get, @grid.bottom.get)
          end

          def _default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil, width: nil)
              if x and width
                  @grid.plan x: x
                  @width << width
                elsif x and left
                  let(x, left){[_2, (_1 - _2) * 2]} >> [@grid.left, @width]
                elsif x and right
                  let(x, right){[_1 * 2 - _2, (_2 - _1) * 2]} >> [@grid.left, @width]
                elsif width and left
                  @width << width
                  @grid.left << left
                elsif width and right
                  let(width, right){[_2 - _1, _2]} >> [@grid.left, @width]
                elsif left and right
                  let(left, right){[_1, _2 - _1]} >> [@grid.left, @width]
                elsif x
                  @grid.plan(:x) << x
                elsif width
                  @width << width
                elsif left
                  @grid.left << left
                elsif right
                  let(@width, right){_2 - _1} >> @grid.left
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

      def init
        @box = new_rectangle color: Color.new('#2c2c2f')
        @subject = nil
        @options = OptionButtonBox.new self
        @options.plan x: @box.x, width: @box.width
        @offset = pot 0
        @suggestions = arrpot
        @options_limit = pot 5
        let(@suggestions, @offset, @options_limit) do |op, off, ol|
            @options.set_options op, off, ol
        end >> pull
        @enabled = pot false
        care @box, @options
        @options.on :option_selected do |e|
          @on_option_selected.(@suggestions.get[@offset.get + e.index]) if @on_option_selected
        end
    end

    cvs_reader :suggestions, :offset, :enabled
    def options = @options

    def accept_subject(subject)
      leave @subject if @subject
        if subject
            care(@subject = subject)
            subject.nanny = self
            @box.plan x: subject.x, width: subject.width
            let(@options.height, subject.y, subject.height, subject.round) do |obh, sy, sh, sr|
                [sy + sh * 0.5, sy + (obh + sr * 0.5) * 0.5, sh + obh + sr * 0.5]
            end >> @options.plan(:top) >> @box.plan(:y, :height)
            @box.round << subject.round
            @enabled.set true
        else
            @subject = nil
            @enabled.set false
        end
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
        @offset.set{_1 - 1} if @offset.get > 0 
      end
    end

    def hover_down
      if not @options.hover_down
        @offset.set{_1 + 1} if @offset.get + @options_limit.get < @suggestions.get.size
      end
    end

    delegate box: %w[x y width height left right top bottom contains?], 
      options: %w[pass_keyboard press_hovered release_pressed]
    end
end