module Ruby2D
    class Button < Widget
    
        def initialize(text: nil, **na, &on_click)
            super()
            @box = new_rectangle **na
            @text = new_text text, x: @box.x, y: @box.y
            place @box, @text
    
            on :click, &on_click if block_given?
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
            Color.new 'black'
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
end