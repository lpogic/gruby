# frozen_string_literal: true

# Ruby2D::Entity

module Ruby2D
  module Entity
    include CommunicatingVesselSystem
    attr_accessor :parent, :nanny

    def emit(type, event = nil); end

    def contains?(x, y)
      false
    end

    def accept_mouse(e)
      contains?(e.x, e.y) ? self : nil
    end

    def lineage
      @parent.lineage + [self]
    end

    def window = parent.window
  end
end

class Class
  def delegate(**na)
    make_delegate = proc do |d, fn, nfn|
      if fn =~ %r{[=+-/*%]$}
        "def #{nfn}(a); @#{d}.#{fn}(a) end"
      else
        "def #{nfn}(*a, **na, &b); @#{d}.#{fn}(*a, **na, &b) end"
      end
    end

    na.each do |k, v|
      v.each do |n|
        nx = n.split(':')
        ns = nx[0].split('\\')
        nfn = nx[1] || ns[0]
        class_eval(make_delegate.call(k, ns[0], nfn))
        ns[1..].each do |nn|
          class_eval(make_delegate.call(k, ns[0] + nn, nfn + nn))
        end
      end
    end
  end
end
