module Ruby2D
    class Widget < Cluster
    
        def initialize(parent, *una, **na, &b)
            super

            @tab_pass_keyboard = on :key_down do |e|
                if e.key == 'tab'
                    parent.pass_keyboard self, reverse: shift_down
                end
            end
        end
    
        def state
            @state
        end

        def pass_keyboard(*)
            return false if @accept_keyboard_disabled
            window.keyboard_current_object = self
            true
        end
    end
end