module Ruby2D
  module CommunicatingVesselSystem
    class ArrayPot < ConvertedPot
      def initialize(inpot, outpot, drainpot, name: nil)
        super(inpot, outpot, name:)
        @drain = drainpot
      end

      def set(value = nil, &mod)
        value = mod.call(@drain.get, value) if mod
        @inpot.set value
        return self
      end

      def inspect
        if @name
          "ArrayPot:#{object_id}(#{@name})"
        else
          "ArrayPot:#{object_id}(" +
          "@inpot=#{@inpot.inspect} " +
          "@outpot=#{@outpot.inspect}" +
          ")"
        end
      end

      def respond_to_missing?(m, include_all)
        Array.method_defined?(m) || super
      end

      def method_missing(m, *a, &)
        if Array.method_defined? m
          as { _1.send(m, *a, &) }
        else
          super
        end
      end

      def _drain
        @drain
      end

      def _inpot
        super + @outpot._inpot
      end
    end
  end
end
