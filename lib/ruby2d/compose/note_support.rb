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
              @objects = options[offset, visible_options_limit].each_with_index.map do |o, i|
                if @buttons[i]
                  b = @buttons[i]
                else
                  b = @buttons[i] = new_button(style: 'option')
                  b.disable :accept_keyboard
                  b.on :click do
                    emit :option_selected, OpitonSelectedEvent.new(i, b)
                  end
                  @grid.rows.set{(_1 || []) + [b.height]}
                  s = @grid.sector(-1, -1)
                  b.plan left: s.left, y: s.y, width: @width
                end
                b.text << o
                b
              end
          end

          delegate grid: %w[x y top bottom left right width height]

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
        @options_box = OptionButtonBox.new self
        @options_box.plan x: @box.x, width: @box.width
        @offset = pot 0
        @options = arrpot
        @max_visible_options = pot 5
        let(@options, @offset, @max_visible_options) do |op, off, mvo|
            @options_box.set_options op, off, mvo
        end >> pull
        @enabled = pot false
        @objects << @box << @options_box
        @options_box.on :option_selected do |e|
          @on_option_selected.(@options.get[@offset.get + e.index]) if @on_option_selected
        end
    end

    cvs_reader :options, :offset, :enabled

    def accept_subject(subject)
        if @subject
            @subject.nanny = nil
            @objects.delete @subject
        end
        if subject
            @objects << @subject = subject
            subject.nanny = self
            @box.plan x: subject.x, width: subject.width
            let(@options_box.height, subject.y, subject.height, subject.round) do |obh, sy, sh, sr|
                [sy + sh * 0.5, sy + (obh + sr * 0.5) * 0.5, sh + obh + sr * 0.5]
            end >> (@options_box.plan(:top) + @box.plan(:y, :height))
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

    delegate box: %w[x y width height left right top bottom contains?], options_box: %w[pass_keyboard]
    end
end