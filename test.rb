require 'ruby2d'
include CommunicatingVesselsSystem

module Ruby2D
    class Window
        def keys_down
            @keys_down
        end
    end
end

set background: 'gray', resizable: true
win = get :window
win.on :key_down do |e|
    win.close if e.key == 'escape'
end

class Textline < Widget

    class Selection
        def initialize(start = 0, length = 0)
            @start = start
            @length = length
        end

        attr_reader :start, :length

        def move(start_offset, length_offset)
            Selection.new @start + start_offset, @length + length_offset
        end
    end

    class Pen < Cluster
        def initialize(text)
            super()
            @enabled = pot false
            @text = text
            @position = pot 0
            @rect = new_rectangle border: 0, round: 0, color: 'black'
            @rect.y = text.y
            @rect.height = text.size
            @rect.width = 2
            @rect.right = let(@position, @text.left, @text.text) do |pos, l, t|
                pos <= 0 ? l : l + text.font.get.size(t[0, pos])[:width]
            end
        end

        pot_accessor(
            :enabled
        )
        pot_reader(
            :position
        )

        def position=(pos)
            @position.let(pos, @text.text{_1.length}){_1.clamp(0, _2)}
        end

        def render
            @rect.render if @enabled.get
        end
    end

    class Car < Cluster
        def initialize(text)
            super()
            @enabled = pot true
            @text = text
            @tl = @text.text{_1.length}
            @coordinates = pot Selection.new
            @rect = new_rectangle border: 0, round: 0, color: '#36921b'
            @rect.y = text.y
            @rect.height = text.size
            let(@coordinates, @text.left, @text.text, @text.font) do |c, tl, t, f|
                l = c.length
                s = c.start
                if l > 0 and s < t.length and s + l <= t.length
                    w = f.size(t[s, l])[:width]
                    lw = f.size(t[0, s + l])[:width]
                    [tl + lw - w, w]
                else
                    [0, 0]
                end
            end >> [@rect.left, @rect.width]
        end

        pot_accessor(
            :enabled,
            :coordinates
        )

        def render
            @rect.render if @enabled.get and @coordinates.get.length > 0
        end

    end

    def initialize(text: nil, x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil)
        super()
        @padding_x = pot 20
        @box = new_rectangle x: x, y: y, left: left, right: right, top: top, bottom: bottom
        @text_value = pot text.force_encoding('utf-8')
        @text = new_text '', left: let(@box.left, @padding_x){_1 + _2 / 2}, y: @box.y
        @text_offset = pot 0
        @text.text = let(@text_value, @box.width, @text_offset, @padding_x, @text.size) do |tv, bw, to, px|
            t = tv[to..]
            t[0, @text.font.get.measure(t, bw - px)]
        end
        @pen = Pen.new @text
        @pen.enabled = @keyboard_current
        @selection = pot Selection.new
        @car = Car.new @text
        @car.coordinates = let(@selection, @text_offset){_1.move(-_2, 0)}
        @car.enabled = @keyboard_current
        
        add @box
        add @car
        add @text
        add @pen

        on :key_down do |e|
            @text.width = @text.width.get / 2 if e.key == 'f1'
        end

        on @keyboard_current do |kc|
            enable_text_input kc
        end

        on :key_type do |e|
            case e.key
            when 'left'
                pen_left(shift_down, ctrl_down)
            when 'right'
                pen_right(shift_down, ctrl_down)
            when 'backspace'
                po = @pen.position.get
                to = @text_offset.get
                if po > 0
                    tv = @text_value.get
                    @text_value.set(tv[0, to + po - 1] + tv[to + po..])
                    @pen.position.set(po - 1)
                elsif @text_offset.get > 0
                    tv = @text_value.get
                    @text_value.set(tv[0, to - 1] + tv[to..])
                    @text_offset.set(to - 1)
                end
            when 'delete'
                po = @pen.position.get
                to = @text_offset.get
                tv = @text_value.get
                if po + to < tv.length
                    @text_value.set(tv[0, to + po] + tv[to + po + 1..])
                end
            end
        end

        on :key_text do |e|
            txt = e.text
            po = @pen.position.get
            to = @text_offset.get
            tv = @text_value.get
            if po + to == 0
                @text_value.set(txt + tv)
            elsif po + to < tv.length
                @text_value.set(tv[..to + po - 1] + txt + tv[to + po..])
            else
                @text_value.set(tv + txt)
            end
            @pen.position.set(po + 1)
        end


        # on :key_press do |e|
        #     p e
        #     case e.key
        #     when :right
        #         @pen.position = @pen.position.get + 1
        #     when :left
        #         @pen.position = @pen.position.get - 1
        #     end
        # end

    end

    pot_accessor(
        :padding_x,
        'color' => [:box, :color],
        'border_color' => [:box, :border_color],
        'border' => [:box, :border],
        'round' => [:box, :round],
        'text' => :text_value,
        'text_visible' => [:text, :text],
        'text_font' => [:text, :font_path],
        'text_size' => [:text, :size],
        'text_color' => [:text, :color],
        ['w', 'width'] => [:box, :width],
        'pen_position' => [:pen, :position]
    )

    pot_reader(
        :text_offset
    )

    def text_offset=(to)
        @text_offset.let(to, @text_value.as{_1.length}){_1.clamp(0, _2)}
    end

    def padding_y=(py)
        @box.h = let_sum(@text.height, py)
    end

    def contains?(x, y)
        @box.contains?(x, y)
    end

    def pen_left(selection = false, word_step = false)
        po = @pen.position.get
        to = @text_offset.get
        poto = po + to
        if selection
            if poto > 0
                s = @selection.get
                if s.length > 0
                    if poto == s.start
                        @selection.set(s.move(-1, 1))
                    elsif poto == s.start + s.length
                        @selection.set(s.move(0, -1))
                    else
                        @selection.set(Selection.new poto - 1, 1)
                    end
                else
                    @selection.set(Selection.new poto - 1, 1)
                end
            end
        else
            @selection.set(Selection.new)
        end

        if po - 1 > 0
            @pen.position = po - 1
        else 
            if to > 0
                @text_offset.set(to - 1)
            else
                @pen.position = po - 1
            end
        end
    end

    def pen_right(selection = false, word_step = false)
        po = @pen.position.get
        to = @text_offset.get
        tvl = @text_value.get.length
        poto = po + to
        if selection
            if poto < tvl
                s = @selection.get
                if s.length > 0
                    if poto == s.start
                        @selection.set(s.move(1, -1))
                    elsif poto == s.start + s.length
                        @selection.set(s.move(0, 1))
                    else
                        @selection.set(Selection.new poto, 1)
                    end
                else
                    @selection.set(Selection.new poto, 1)
                end
            end
        else
            @selection.set(Selection.new)
        end

        tl = @text.text.get.length
        if po + 1 < tl
            @pen.position = po + 1
        else 
            if to + tl + 1 <= @text_value.get.length
                @text_offset.set(to + 1)
            else
                @pen.position = po + 1
            end
        end
    end
end

class BasicTextlineStyle
    include CommunicatingVesselsSystem

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
        20
    end

    def text_font
        @text_font
    end

    def border
        1
    end

    def round
        8
    end

    def color
        let @element.state do |s|
            if s[:pressed]
                @color_pressed
            elsif s[:hovered]
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
        let @element.state do |s|
            if s[:pressed]
                @text_color_pressed
            else
                @text_color
            end
        end
    end

    def padding_x
        20
    end

    def padding_y
        10
    end
end

def make_outfit(element, style)
    case element
    when Textline
        case style
        when 'default'
            return BasicTextlineStyle.new(
                element, 
                Color.new('#3c3c3f'), 
                Color.new('#1084E9'), 
                Color.new('#1084E9'), 
                Color.new('white'), 
                Color.new('#DFDFDF'),
                'consola'
            )
        when 'green'
            return BasicTextlineStyle.new(
                element, 
                Color.new('#2c9b33'), 
                Color.new('#23b22d'), 
                Color.new('#2b642f'), 
                Color.new('white'), 
                Color.new('#DFDFDF'),
                'consola'
            )
        end
    end
end

def textline(text = '', x: 200, y: 100, left: nil, right: nil, top: nil, bottom: nil, width: nil, w: nil,
    style: 'default', text_font: nil, text_size: nil, text_color: nil, round: nil, r: nil, color: nil, border: nil, b: nil, border_color: nil, 
    padding_x: nil, px: nil, padding_y: nil, py: nil, &on_click)

    tln = Textline.new text: text, x: x, y: y, left: left, right: right, top: top, bottom: bottom, &on_click
    style = make_outfit tln, style
    tln.text_font = text_font || style.text_font
    tln.text_size = text_size || style.text_size
    tln.text_color = text_color || style.text_color
    tln.round = round || r || style.round
    tln.color = color || style.color
    tln.border = border || b || style.border
    tln.border_color = border_color || style.border_color
    tln.padding_x = padding_x || px || style.padding_x
    tln.padding_y = padding_y || py || style.padding_y
    tln
end


tln = textline("ąText line Text line Text line", x: 200, text_size: 14)
win.add tln
win.keyboard_current_object = tln

# btn = win.button("Przyciśnij mnie!")
# btn1 = win.button("Przyciśnij mnie!", x: 400, style: 'green') do
#     btn.text = "Teraz mnie!"
#     btn1.text = "Przyciśnij mnie!"
# end
# btn.on :click do
#     btn.text = "Przyciśnij mnie!"
#     btn1.text = "Teraz mnie!"
# end
# win.add btn1
# win.add btn
# btn1.text_size = let(btn1.state){_1[:hovered] ? 22 : 20}
# win.add(Text.new("X", x: 30, y: 30))
# win.add(Circle.new(x: win.x, y: win.y, radius: 300))
# win.add(Circle.new(x: win.width{_1 / 2}, y: win.height{_1 / 2}, radius: 250, color: 'black'))
# win.add(Circle.new(x: win.width{_1 / 2}, y: win.height{_1 / 2}, radius: 200, color: 'green'))
# win.add(Circle.new(x: win.width{_1 / 2}, y: win.height{_1 / 2}, radius: 150, color: 'red'))
# win.add(Circle.new(x: win.width{_1 / 2}, y: win.height{_1 / 2}, radius: 100, color: 'blue'))
# win.add(Circle.new(x: win.width{_1 / 2}, y: win.height{_1 / 2}, radius: 50, color: 'white'))
# win.add(Text.new("XD", x: win.x, y: win.y, color: 'black'))
# win.add btn1
# win.add(Circle.new(x: 350, y:250, radius: 100))
# win.add(Circle.new(x: 250, y:250, radius: 100))
# win.add(Line.new(x1: 300, y1:100, x2: 220, y2: 150))
# win.add(Quad.new(x1: 500, y1:400, color: 'black'))

show


