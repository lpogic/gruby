module Ruby2D
    class TextNote < Note
        def color_plan(color: nil, **)
            if color
                self.color << color
            end
        end
    
        def border_color_plan(border_color: nil, **)
            if border_color
                self.border_color << border_color
            end
        end
    
        def text_color_plan(text_color: nil, **)
            if text_color
                self.text_color << text_color
            end
        end
    end
end