module Kernel
    # make an alias of the original require
    alias_method :original_require, :require
  
    # rewrite require
    def require name
        if name == 'ruby2d/ruby2d'
            original_require name
        elsif name.start_with?('ruby2d')
            original_require "./lib/#{name}"
        else
            original_require name
        end
    end
end

require 'ruby2d/core'
include Ruby2D
extend Ruby2D::DSL
include CommunicatingVesselSystem

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

class Multitext < Cluster
    TextPart = Struct.new(:text, :length)

    pot_reader :text

    pot_accessor :left, :right, :top, :bottom

    def initialize(text, size: 20, style: nil, font: nil,
        x: 0, y: 0, color: nil,
        left: nil, right: nil, top: nil, bottom: nil)
        super()
        @x = pot x
        @y = pot y
        @text = pot text
        @width = pot
        @parts = compot do |parts, s|
            let_sum(*parts.map{_1.text.width}) >> @width
            # @width.let(*parts.map{_1.text.width}){|*ptw| ptw.sum}
            remove s.get.map{_1.text} if not s.get.nil?
            add *parts.map{_1.text}
            parts
        end
        parts = []
        r = nil
        color.each_with_index do |lc, i|
            length, color = *lc
            if i == 0
                r = pot.let(length){0..._1}
            else
                r = pot.let(length, r){_2.max + 1.._2.max + _1}
            end
            text = new_text(let(@text, r){_1[_2]}, size: size, style: style, font: font, color: color, y: @y)
            text.plan :left
            parts << TextPart.new(text, r)
        end
        @parts.set parts
        parts[0].text.left = self.left
        parts.each_cons(2) do |pt|
            pt[1].text.left = pt[0].text.right
        end
    end

    def plan(*params)
        if params.include?(:left)
          plan_params [:left, :width], [:x, :right] do [_1 + _2 / 2, _1 + _2] end
        elsif params.include?(:right)
          plan_params [:right, :width], [:x, :left] do [_1 - _2 / 2, _1 - _2] end
        elsif params.include?(:x)
          if @left
            plan_params [:x, :width], [:left, :right] do [_1 - _2 / 2, _1 + _2 / 2] end
          end
        end
  
        if params.include?(:top)
          plan_params [:top, :height], [:y, :bottom] do [_1 + _2 / 2, _1 + _2] end
        elsif params.include?(:bottom)
          plan_params [:bottom, :height], [:y, :top] do [_1 - _2 / 2, _1 - _2] end
        elsif params.include?(:y)
          if @top
            plan_params [:y, :height], [:top, :bottom] do [_1 - _2 / 2, _1 + _2 / 2] end
          end
        end
        params.map{instance_variable_get("@#{_1}")}
    end


    def _left
        make_left_right if not @left
        @left
    end

    def _right
        make_left_right if not @right
        @right
    end

    def make_left_right
        let(@x, @width){[_1 - _2 / 2, _1 + _2 / 2]} >> [@left = pot, @right = pot]
        @left.lock_inlet
        @right.lock_inlet
    end

    def _top
        make_top_bottom if not @top
        @top
    end

    def _bottom
        make_top_bottom if not @bottom
        @bottom
    end

    def make_top_bottom
        let(@y, @height){[_1 - _2 / 2, _1 + _2 / 2]} >> [@top = pot, @bottom = pot]
        @top.lock_inlet
        @bottom.lock_inlet
    end
end

class Textline < Widget

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
    end

    class Pen < Cluster
        def initialize(text)
            super()
            @enabled = pot false
            @text = text
            @position = pot 0
            @rect = new_rectangle border: 0, round: 0, color: 'black'
            @rect.y = text.y
            @rect.height = text.size.as{_1 * 5 / 4}
            @rect.plan :right, :width
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
        @pen_position = compot(@text_value.as{_1.length}) do |tvl, v|
            if v < 0 then 0
            elsif v > tvl then tvl
            else v
            end
        end.set 0
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

        on @keyboard_current do |kc|
            enable_text_input kc
        end

        on @pen_position do |pp, ppp|
            to = @text_offset.get
            if pp - to < 0
                @text_offset.set(pp)
                @pen.position = 0
            else
                tl = @text.text.get.length
                if to + tl < pp
                    @text_offset.set(pp - tl)
                    @pen.position = tl
                else
                    @pen.position = pp - to
                end
            end 
        end


        on :key_type do |e|
            case e.key
            when 'left'
                pen_left(shift_down, ctrl_down ? alt_down ? :class : :word : :character)
            when 'right'
                pen_right(shift_down, ctrl_down ? alt_down ? :class : :word : :character)
            when 'backspace'
                if @selection.get.empty?
                    pen_erase(:left)
                else
                    selection_erase
                end
            when 'delete'
                if @selection.get.empty?
                    pen_erase(:right)
                else
                    selection_erase
                end
            when 'home'
                pen_left(shift_down, @pen_position.get)
            when 'end'
                pen_right(shift_down, @text_value.get.length - @pen_position.get)
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
            @pen_position.set(po + 1)
        end

    end

    pot_accessor(
        :padding_x,
        :pen_position,
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
                    elsif pp == s.start + s.length
                        @selection.set(s.move(0, -st))
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
                        @selection.set(s.move(st, -st))
                    elsif pp == s.start + s.length
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

    def selection_erase()
        selection = @selection.get
        tv = @text_value.get
        @text_value.set(tv[...selection.start] + tv[selection.start + selection.length..])
        @pen_position.set(selection.start)
        @selection.set(Selection.new)
    end


    private

    def class_step_right(text, start)
        return 0 if start + 1 >= text.length
        cc = character_class(text[start])
        text[start + 1..].each_char.take_while{character_class(_1) == cc}.count
    end

    def word_step_right(text, start)
        return 0 if start + 1 >= text.length
        cc = character_class(text[start]) == :blank
        cnt = text[start + 1..].each_char.take_while{(character_class(_1) == :blank) == cc}.count
        if character_class(text[start + cnt + 1]) == :blank
            cnt += text[start + cnt + 1..].each_char.take_while{character_class(_1) == :blank}.count
        end
        cnt
    end

    def class_step_left(text, start)
        return 0 if start <= 0
        cc = character_class(text[start])
        text[..start - 1].reverse.each_char.take_while{character_class(_1) == cc}.count
    end

    def word_step_left(text, start)
        return 0 if start <= 0
        cc = character_class(text[start]) == :blank
        cnt = text[..start - 1].reverse.each_char.take_while{(character_class(_1) == :blank) == cc}.count
        if character_class(text[start - cnt - 1]) == :blank
            cnt += text[..start - cnt - 1].reverse.each_char.take_while{character_class(_1) == :blank}.count
        end
        cnt
    end

    def character_class(ch)
        case ch
        when /\p{Ll}/ then :loweralpha
        when /\p{Lu}/ then :upperalpha
        when /\p{Nd}/ then :digit
        when /\p{Blank}/ then :blank
        else :other
        end
    end
end

class BasicTextlineStyle
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
win.add(Multitext.new("XDXDXDXDXDXDXDXD", x: 400, y: 400, color: [[6, 'black'], [6, 'white'], [6, 'black']]))
win.add(Text.new("XDXDXDXDXDXDXDXD", x: 400, y: 400, color: 'red'))

show