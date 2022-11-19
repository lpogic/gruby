module Ruby2D
    class Button < Widget

        cvs_accessor :space_pressed

        alias mouse_pressed pressed

        def pressed
            let(mouse_pressed, space_pressed).or
        end
    
        def initialize(text: nil, **na, &on_click)
            super()
            @space_pressed = pot false
            @box = new_rectangle **na
            @text = new_text text, x: @box.x, y: @box.y
            place @box, @text
    
            on :click, &on_click if block_given?

            on :key_down do |e|
                @space_pressed.set true if e.key == 'space'
            end

            on @keyboard_current do |kc|
                @space_pressed.set false
            end

            on :key_up do |e|
                if e.key == 'space'
                    if @space_pressed.get
                        @space_pressed.set false
                        emit :click if not pressed.get
                    end
                end
            end
        end

        delegate box: %w[x y left top right bottom width height color border_color border round plan fill contains?]

        cvs_accessor(
            'color' => [:box, :color],
            'border_color' => [:box, :border_color],
            'border' => [:box, :border],
            'round' => [:box, :round],
            'text' => [:text, :text],
            'text_size' => [:text, :size],
            'text_color' => [:text, :color]
        )
    
        def padding_x=(px)
            @box.w = let(@text.width, px).sum
        end
    
        def padding_y=(py)
            @box.h = let(@text.height, py).sum
        end
    end


    class BasicButtonStyle
        include CommunicatingVesselSystem
    
        def initialize(element, 
            color, color_hovered, color_pressed, 
            text_color, text_color_pressed)
            @element = element
            @color = color
            @color_hovered = color_hovered
            @color_pressed = color_pressed
            @text_color = text_color
            @text_color_pressed = text_color_pressed
        end
    
        def text_size
            14
        end
    
        def border
            1
        end
    
        def round
            12
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
                kc ? Color.new('#7b00ae') : Color.new('blue')
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
    
        def padding_x
            20
        end
    
        def padding_y
            10
        end
    end
end