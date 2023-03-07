module A

  def xd sym
    @var ||= 0
    foo_sym = "foo_#{sym}".to_sym
    alias_method foo_sym, sym
    define_method sym do
      p @var += 1
      send(foo_sym)
    end
  end
end

class B
  extend A
end

class C < B

  def bar
    p __method__
  end

  xd :bar
end

c = C.new
c.bar
cc = C.new
cc.bar
c.bar