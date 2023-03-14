require_relative "sketch_setup"
require 'benchmark'

album! %w[1 2 3] do
  x << host.mouse_x
end

show
