module Ruby2D
    class Multitext < Cluster
        include Renderable
        TextPart = Struct.new(:text, :length)

        cvs_reader :height, :width, :left, :right, :top, :bottom, :x, :y, :size, :text


        def init(text, size: 20, style: nil, font: nil, portions: nil, **na)
            @text = pot.let text
            @size = pot.let size
            @font_path = compot{Font.path _1}.let(font || Font.default)
            @font_style = pot.let style
            @font = pot(@font_path, @size, @font_style){Font.load(_1, _2, _3)}
            @x = pot 100
            @y = pot 100
            @width = pot
            @height = pot
            @parts = compot pull: true do |parts, s|
                let(*parts.map{_1.text.width}).sum >> @width
                @height.let(parts.empty? ? 0 : parts[0].text.height)
                drop *s.get.map{_1.text} if not s.get.nil?
                place *parts.map{_1.text}
                parts
            end
            self.portions = portions ? portions : [{color: 'white', range: 0..}]
            plan **na
        end

        def font 
            @font
        end

        def font=(f)
            @font_path.let f
        end

        def _default_plan(x: nil, y: nil, left: nil, right: nil, top: nil, bottom: nil)
          if x
            @x.let x
          elsif left
            let(left, width){_1 + _2 * 0.5} >> @x
          elsif right
            let(right, width){_1 - _2 * 0.5} >> @x
          end
    
          if y
            @y.let y
          elsif top
            let(top, height){_1 + _2 * 0.5} >> @y
          elsif bottom
            let(bottom, height){_1 - _2 * 0.5} >> @y
          end
        end
    
        def _cvs_left
          let(@x, @width){_1 - _2 * 0.5}
        end
    
        def _cvs_right
          let(@x, @width){_1 + _2 * 0.5}
        end
    
        def _cvs_top
          let(@y, @height){_1 - _2 * 0.5}
        end
    
        def _cvs_bottom
          let(@y, @height){_1 + _2 * 0.5}
        end

        def portions=(portions)
            parts = portions.map do |prt|
                range = prt[:range]
                color = prt[:color]
                text = new_text(let(@text, range){_1[_2]}, size: @size, style: @font_style, font: @font_path, color: color, y: @y)
                text.plan :left
                TextPart.new(text, range)
            end
            @parts.set parts
            parts[0].text.left = self.left
            parts.each_cons(2) do |pt|
                pt[1].text.left = pt[0].text.right
            end
        end
    end
end