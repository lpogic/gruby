class Foo
  def foo(a: nil, **)
    p a
  end
end

class Foo1 < Foo
  def foo(b: nil, **)
    p b
    super
  end
end

f = Foo1.new
f.foo a: :D, b: :P