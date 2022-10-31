require 'ruby2d'
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

x = pot 0
y = pot 1
let(x, y){p "XD"; [_1, _2]} >> [y, x]

show