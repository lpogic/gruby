a = proc{|a, b| a ** 3 + b}
c = a.curry[2]
p c.call(6)