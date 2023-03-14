

class FOO
  def foo
    p :D
  end
end

foo = FOO.new
m = foo.method(:foo)
foo.define_singleton_method :foo do
  p :P
end
foo.foo
foo.define_singleton_method m.name, m
foo.foo