require_relative "sketch_setup"
require 'benchmark'

button! "1" do
  a = 1
  on :click do
    b = text.val.to_i
    a, text.val = b, b + a
  end
end

show
