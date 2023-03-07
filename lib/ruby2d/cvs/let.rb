require "weakref"

module Ruby2D
  module CommunicatingVesselSystem
    class Let
      class DuplicatedConnectionError < StandardError
      end

      class DisconnectedLetUpdate < StandardError
      end

      def initialize(inpot, name: nil, &block)
        @function = block
        @inpot = inpot
        @connected = false
        @name = name
      end

      def get
        i = @inpot.map(&:get)
        if @function
          return @function.call(*i)
        else
          return i.size > 1 ? i : i[0]
        end
      end

      def >>(target)
        return _copy >> target if @connected

        case target
        when Pot
          _connect target
        when Let
          _connect target.inpot # co z funkcją z jednym wejściem?
        when Array
          raise "Only Pot, Let or Array of Pots allowed as the right side" if not target.all?{_1.is_a? Pot}
          _connect target
        else raise "Only Pot, Let or Array of Pots allowed as the right side"
        end
        self
      end

      def as(&b)
        if @function
          Let.new(@inpot) do |*a|
            b.call(*@function.call(*a))
          end
        else
          Let.new(@inpot, &b)
        end
      end

      def pot
        pt = BasicPot.new
        self >> pt
        return pt
      end

      def arrpot(&)
        CommunicatingVesselSystem.array_pot { _1.map(&).compact.flatten } << self
      end

      def inspect
        outpot = _outpot
        "Let:#{object_id}(" + 
        "@inpot=#{@inpot.map { "Pot:" + _1.object_id.to_s }} " + 
        "@connected=#{@connected} " +
        (@connected ? "@outpot=#{outpot.nil? ? 'nil' : outpot.is_a?(Array) ? outpot.map { "Pot:" + _1.object_id.to_s } : outpot.object_id} " : "") + 
        "@function=#{@function}" +
        ")"
      end

      def respond_to_missing?(m, include_all)
        m == :to_ary || Array.method_defined?(m) || super
      end

      # dla funkcji agregujących np. let(*xes).max,    let(a, b, c).max
      def method_missing(m, *a, &)
        if m == :to_ary
          super
        elsif Array.method_defined? m
          _compose(m, *a, &)
        else
          super
        end
      end

      def _function
        @function
      end

      def _inpot
        @inpot
      end

      def _copy
        Let.new @inpot, &@function
      end

      def _compose(m, *arg, &)
        if @function
          Let.new(@inpot) do |*a|
            r = *@function.call(*a)
            r.send(m, *arg, &)
          end
        else
          Let.new(@inpot) do |*a|
            a.send(m, *arg, &)
          end
        end
      end

      def _connect(outpot, pull: true)
        raise DuplicatedConnectionError if @connected

        ao = outpot.to_a
        _loop_test(*ao)
        to_pull = ao.map do
          _1._set_inlet self
          _1._outdate
        end.reduce(:+)
        @outpot = outpot.is_a?(Array) ? outpot.map { WeakRef.new _1 } : WeakRef.new(outpot)
        @inpot.each { _1._add_outlet(self) }
        @connected = true
        to_pull.each(&:get) if pull
      end

      def _outpot
        o = nil
        if @outpot.is_a? Array
          o = []
          @outpot = @outpot.map do |wr|
            if wr
              begin
                o << wr.__getobj__
                wr
              rescue
                o << nil
                nil
              end
            else
              o << nil
              nil
            end
          end
        elsif not @outpot.nil?
          begin
            o = @outpot.__getobj__
          rescue
            @outpot = nil
          end
        end
        return o
      end

      def _loop_test(*outpot)
        seed = Pot._dfs_next_seed
        path_found = _inpot.map do |i|
          i._dfs_path(seed: seed).find do |path|
            outpot.include?(path.last)
          end
        end.find(&:itself)
        raise "Pot loop detected:\n" + path_found.each_with_index.map { "#{_2 + 1}. #{_1.inspect}" }.join("\n") if path_found
      end

      def _update
        raise DisconnectedLetUpdate if !@connected

        outpot = self._outpot
        oc = outpot.to_a.compact
        if oc.empty?
          _disconnect
          return
        end
        oc.each { _1._recent = true }
        result = self.get
        if outpot.is_a? Array
          result.zip(outpot).each { |r, o| o&._set r }
        else
          outpot._set result
        end
        result
      end

      def _disconnect
        return if !@connected
        @inpot.each { _1._delete_outlet(self) }
        @connected = false
        _outpot.to_a.compact.each { _1._set_inlet(false) }
        @outpot = nil
      end

      def _delete_outpot(to_delete)
        if @outpot.is_a? Array
          @outpot = @outpot.map { (_1.nil? || !_1.weakref_alive? || _1.__getobj__ == to_delete) ? nil : _1 }
          _disconnect if @outpot.compact.empty?
        else
          @outpot = nil if @outpot.nil? || !@outpot.weakref_alive? || @outpot.__getobj__ == to_delete
          _disconnect if @outpot.nil?
        end
        return self
      end

      alias_method :cancel, :_disconnect
    end
  end
end