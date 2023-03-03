require_relative "./communicating_vessel_system"

module Ruby2D
  module CVS
    include CommunicatingVesselSystem

    def pot(...)
      CommunicatingVesselSystem.pot(...)
    end

    def cpot(...)
      CommunicatingVesselSystem.converted_pot(...)
    end

    def arrpot(...)
      CommunicatingVesselSystem.array_pot(...)
    end

    def let(...)
      CommunicatingVesselSystem.let(...)
    end

    def let_if(a, b, c)
      let a, b, c do |av, bv, cv|
        av ? bv : cv
      end
    end
  end
end

class Class
  def cvs_reader(*a)
    make_reader = proc do |n|
      ns = n.split(":")
      ns[1] ||= ns[0]
      pt = "c = defined?(self.cvs_#{ns[0]}) ? self.cvs_#{ns[0]} : @#{ns[0]}"
      class_eval("def #{ns[1]}(&b); #{pt}; block_given? ? c.as(&b) : c;end", __FILE__, __LINE__)
    end

    a.each do |n|
      if n.is_a? Array
        n.each { make_reader.call(_1.to_s) }
      else
        make_reader.call(n.to_s)
      end
    end
  end
end
