module Ruby2D
    class Widget < Cluster
    
        def initialize()
            super()
            @state = pot({})
            on :mouse_down do
                update_state :hovered, :pressed
            end
            on :mouse_up do
                update_state unset: [:pressed]
            end
            on :mouse_in do
                update_state :hovered
            end
            on :mouse_out do
                update_state unset: [:hovered, :pressed]
            end
        end
    
        def state
            @state
        end
    
        def update_state(*set, unset: [])
            @state.set(@state.get.merge(set.map{[_1, _1]}.to_h).except(*unset))
        end
    end
end