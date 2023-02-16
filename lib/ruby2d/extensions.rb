class Object
  def timems
    now = Time.now
    ((now.to_i * 1e3) + (now.usec / 1e3)).to_i
  end

  def array
    is_a?(Array) ? self : [self]
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
  def def_struct(*una, accessors: false, readers: false, to_h: true, breed: true, **na)
      class_eval("def initialize(#{(una.map { _1.to_s + ': nil' } + na.map { |k, v| k.to_s + ':' + v.to_s }).join(',')}, **);" +
          "#{(una + na.keys).map { "@#{_1} = #{_1};" }.join}end")
      attr_accessor(*una) if accessors
      attr_reader(*una) if readers and !accessors
      class_eval("def to_hash; {#{(una + na.keys).map { "#{_1}: @#{_1}," }.join}} end") if to_h
      class_eval("def breed(**params); self.class.new **self, **params end") if to_h && breed
  end
end