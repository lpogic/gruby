require_relative "./communicating_vessel_system"

module Ruby2D
  module CVS
    include CommunicatingVesselSystem

    @@debug = false
    def self.debug=(debug)
      @@debug = debug
    end

    def self.debug = @@debug

    def pot(*a, name: nil, **na, &b)
      name = name ? name : @@debug ? caller(1..1).first : nil
      CommunicatingVesselSystem.pot(*a, **na, name: name, &b)
    end

    def cpot(*a, name: nil, **na, &b)
      name = name ? name : @@debug ? caller(1..1).first : nil
      CommunicatingVesselSystem.converted_pot(*a, **na, name: name, &b)
    end

    def arrpot(*a, name: nil, **na, &b)
      name = name ? name : @@debug ? caller(1..1).first : nil
      CommunicatingVesselSystem.array_pot(*a, **na, name: name, &b)
    end

    def let(*a, name: nil, **na, &b)
      name = name ? name : @@debug ? caller(1..1).first : nil
      CommunicatingVesselSystem.let(*a, **na, name: name, &b)
    end

    def case_let(*a)
      let *a do |*av|
        av.each_slice(2).find{ _1.size == 2 && _1[0] }&.at(1) || av.last
      end
    end

    def let_if(a, b, c)
      let a, b, c do |av, bv, cv|
        av ? bv : cv
      end
    end

    def let_recent(*a)
      let *a.map{_1.as{|v| [v, timems]}} do |*at|
        at.max{_1[1] <=> _2[1]}[0]
      end
    end
  end
end

class Class
  def cvsa(*a)
    make_method = proc do |n|
      ns = n.split(":")
      ns[1] ||= ns[0]
      pt = "c = defined?(self.cvs_#{ns[0]}) ? self.cvs_#{ns[0]} : @#{ns[0]}"
      class_eval("def #{ns[1]}(&b); #{pt}; block_given? ? c.as(&b) : c;end", __FILE__, __LINE__)
    end

    a = a.flatten
    a.each do |n|
      make_method.call(n.to_s)
    end
  end
end
