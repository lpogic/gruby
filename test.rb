require 'ruby2d'
include CommunicatingVesselSystem

module Ruby2D
  class Window
    attr_reader :keys_down
  end
end

set background: 'gray', resizable: true
win = get :window
win.on :key_down do |e|
  win.close if e.key == 'escape'
end

x = pot 0
y = pot 1
let(x, y, x) do
  p 'XD'
  [_1, _2]
end >> [y, x]

show
