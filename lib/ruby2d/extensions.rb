class Object
  def timems
    now = Time.now
    ((now.to_i * 1e3) + (now.usec / 1e3)).to_i
  end

  def array
    is_a?(Array) ? self : [self]
  end

  def behalf origin, &todo
    origin.instance_exec self, &todo
  end
end

class Array
  def all_in?(*o)
    o.all? { include? _1 }
  end

  def any_in?(*o)
    o.any? { include? _1 }
  end

  alias or any?
  alias and all?
end

class Hash
  def all_in?(*o)
    o.all? { has_key? _1 }
  end

  def any_in?(*o)
    o.any? { has_key? _1 }
  end
end

class IO
  def self.ppot(command)
    pt = pot
    Thread.new do
      IO.popen(command) do |io|
        while line = io.gets(chomp: true)
          pt << line
        end
      end
    end
    pt
  end
end

class Class
  def def_struct(*una, accessors: false, readers: false, to_h: true, merge: true, **na)
      class_eval("def initialize(#{(una.map { _1.to_s + ': nil' } + na.map { |k, v| k.to_s + ':' + v.to_s }).join(',')}, **);" +
          "#{(una + na.keys).map { "@#{_1} = #{_1};" }.join}end")
      attr_accessor(*una) if accessors
      attr_reader(*una) if readers and !accessors
      class_eval("def to_hash; {#{(una + na.keys).map { "#{_1}: @#{_1}," }.join}} end") if to_h
      class_eval("def merge(**params); self.class.new **self, **params end") if to_h && merge
  end

  def delegate(**na)
    make_delegate = proc do |d, fn, nfn|
      if %r{[=+-/*%]$}.match?(fn)
        "def #{nfn}(a); @#{d}.#{fn}(a) end"
      else
        "def #{nfn}(*a, **na, &b); @#{d}.#{fn}(*a, **na, &b) end"
      end
    end

    na.each do |k, v|
      v.each do |n|
        nx = n.split(":")
        ns = nx[0].split("\\")
        nfn = nx[1] || ns[0]
        class_eval(make_delegate.call(k, ns[0], nfn))
        ns[1..].each do |nn|
          class_eval(make_delegate.call(k, ns[0] + nn, nfn + nn))
        end
      end
    end
  end
end