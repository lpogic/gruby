module Ruby2D
  module BlockScope
    class Receptionist
      def initialize
        @call_stack = []
      end

      def _top_receiver(method_name)
        @call_stack.reverse_each.find{ _1.respond_to? method_name}
      end

      def _push *top
        @call_stack.push *top
      end
    
      def _pop n = 1
        @call_stack.pop n
      end

      def method_missing m, *a, **na, &b
        _top_receiver(m).send(m, *a, **na, &b)
      end
  
      def respond_to_missing? m
        _top_receiver(m) != nil
      end
    end
  
    @@receptionist = Receptionist.new
  
    def self.push *top
      @@receptionist._push *top
    end
  
    def self.pop n = 1
      @@receptionist._pop n
    end
  
    def self.top *top, &b
      push *top
      r = @@receptionist.instance_eval &b if block_given?
      pop top.size
      return r
    end
  end
end