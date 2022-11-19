module Ruby2D
    class Widget < Cluster
    
        

        def initialize()
            super()

            on :key_down do |e|
                if e.key == 'tab'
                    parent.pass_keyboard self, reverse: shift_down
                end
            end
        end
    
        def state
            @state
        end

        def pass_keyboard(*)
            window.keyboard_current_object = self
            true
        end
    end
end