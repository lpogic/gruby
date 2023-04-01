require_relative "sketch_setup"
require 'benchmark'

# button! "1" do
#   a = 1
#   on :click do
#     b = text.val.to_i
#     a, text.val = b, b + a
#   end
# end

rows! do
  n = note! text: "A" do
    on :click do
      p text.get
    end
  end
  button! width: width do
    on :click do
      n.text.set{ _1 + ((_1[-1] || "@").ord + 1).chr }
    end
  end
end


show
