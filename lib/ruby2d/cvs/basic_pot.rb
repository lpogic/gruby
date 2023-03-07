require "weakref"

module Ruby2D
  module CommunicatingVesselSystem
    class BasicPot < Pot
      def initialize(value = nil, pull: true, recent: true, name: nil)
        super()
        @inlet = nil
        @outlet = []
        @value = value
        @recent = recent
        @pull = pull
        @name = name
      end

      def get
        _update unless @recent
        return @value
      end

      alias_method :val, :get

      def set(value = nil, &mod)
        value = mod.call(get, value) if mod
        _set_inlet(nil)
        od = _outdate
        _set(value)
        od.each(&:get)
        return self
      end

      alias_method :val=, :set

      def let(*v, &)
        if block_given?
          l = Let.new(v.map { _1.is_a?(Pot) ? _1 : BasicPot.new.let(_1) }, &)
        elsif v[0].is_a? Let
          l = v[0]._copy
        elsif v[0].is_a? Pot
          l = Let.new(v)
        else
          return set(v[0])
        end
        l._connect(self)
        return self
      end

      def dependent?
        !!@inlet
      end

      def stop_pull
        pull = @pull
        @pull = false
        yield
        @pull = pull
      end

      def inspect
        if @name
          "BasicPot:#{object_id}(#{@name})"
        else
          "BasicPot:#{object_id}(" + 
          "@recent=#{@recent} @value=#{@value.inspect} " + 
          "@inlet=#{@inlet ? "Let:" + @inlet.object_id.to_s : "nil"} " +
          "@outlet=#{@outlet.map { "Let:" + _1.object_id.to_s }}" +
          ")"
        end
      end

      def _recent
        @recent
      end

      def _recent=(r)
        @recent = r
      end

      def _update
        @recent = true
        @inlet&._update
      end

      def _outdate
        if @recent
          @recent = false
          pull_down = _outlet.map { |ol| ol._outpot.to_a.compact.map { _1._outdate }.reduce([], :+) }.reduce([], :+)
          if pull_down && !pull_down.empty?
            return pull_down
          else
            return @pull ? [self] : []
          end
        else
          return []
        end
      end

      def _set(value)
        @value = value
        @recent = true
      end

      def _outlet
        o = []
        @outlet = @outlet.map do |wr|
          o << wr.__getobj__
          wr
        rescue
          nil
        end.compact
        return o
      end

      def _set_inlet(inlet)
        @inlet&._delete_outpot self
        @inlet = inlet
      end

      def _inlet
        @inlet
      end

      def _inpot
        @inlet ? @inlet._inpot : []
      end

      def _add_outlet(let)
        @outlet.append(WeakRef.new(let)) unless _outlet.include? let
      end

      def _delete_outlet(let)
        @outlet.delete_if { !_1.weakref_alive? or _1.__getobj__ == let }
      end
    end
  end
end
