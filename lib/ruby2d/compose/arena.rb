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
                plan[:x] = self.x if not plan.any_in? :left, :x, :right
                plan[:y] = self.y if not plan.any_in? :top, :y, :bottom
                plan[:width] = self.width if not plan.include?(:width) and element.is_a? Container
                plan[:height] = self.height if not plan.include?(:height) and element.is_a? Container
                element.plan **plan
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
    
        def row(**na, &b)
            append(Row.new(**na), **na, &b)
        end
    
        def col(**na, &b)
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
    end
end