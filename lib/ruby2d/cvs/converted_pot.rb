module Ruby2D
  module CommunicatingVesselSystem
    class ConvertedPot < Pot
      def initialize(inpot, outpot, location: nil)
        super()
        @inpot = inpot
        @outpot = outpot
        @location = location
      end

      def get
        @outpot.get
      end

      alias_method :val, :get

      def set(value = nil, &mod)
        value = mod.call(get, value) if mod
        @inpot.set value
        return self
      end

      alias_method :val=, :set

      def let(...)
        @inpot.let(...)
        return self
      end

      def dependent?
        @inpot.dependent?
      end

      def inspect
        if @location
          "ConvertedPot:#{object_id}(#{@location})"
        else
          "ConvertedPot:#{object_id}(" + 
          "@inpot=#{@inpot.inspect} " +
          "@outpot=#{@outpot.inspect}" +
          ")"
        end
      end

      def _outlet
        @outpot._outlet
      end

      def _update
        @inpot._update
      end

      def _outdate
        @inpot._outdate
      end

      def _recent
        @outpot._recent
      end

      def _recent=(recent)
        @outpot._recent = recent
      end

      def _set(value)
        @inpot._set value
      end

      def _set_inlet(inlet)
        @inpot._set_inlet inlet
      end

      def _inlet
        @outpot._inlet
      end

      def _inpot
        @outpot._inlet._inpot
      end

      def _add_outlet(let)
        @outpot._add_outlet(let)
      end

      def _delete_outlet(let)
        @outpot._delete_outlet(let)
      end

      def _converted_pot_inpot
        @inpot
      end

      def _converted_pot_outpot
        @outpot
      end
    end
  end
end