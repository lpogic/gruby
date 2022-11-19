module Ruby2D
    class Arena < Cluster

        def initialize()
            super()
            @_top = self
        end

        def parent=(parent)
            super
            build
        end

        def build
        end
    
        def append(element, **plan)
            if @_top == self
                plan[:x] = self.x if not plan_x_defined? plan
                plan[:y] = self.y if not plan_y_defined? plan
                element.plan **plan
                plan width: element.width, height: element.height
                place element
            else
                @_top.append(element, **plan)
            end
            top, @_top = @_top, element
            if block_given?
                r = yield element
                if r.is_a? String
                    element.append(new_note text: r, style: 'text')
                end
            end
            @_top = top
            element
        end

        def plan(**a)
        end
    
        def row(height = nil, **na, &b)
            na[:height] = height if height
            append(Row.new(**na), **na, &b)
        end
    
        def col(width = nil, **na, &b)
            na[:width] = width if width
            append(Col.new(**na), **na, &b)
        end
    
        def text(t, **na)
            append(new_note(text: t, style: 'text', **na), **na)
        end
    
        def note(**na)
            append(new_note(**na), **na)
        end
    
        def button(t, **na)
            append(new_button(text: t), **na)
        end

        def rect(**ona)
            append(new_rectangle(**ona), **ona)
        end

        def circle(**ona)
            append(new_circle(**ona), **ona)
        end
    end
end