# SYSTEM ZMIENNYCH POWIĄZANYCH

# Zmienne wyjściowe (outpot) muszą być podane jawnie, a nie jako efekt uboczny np {@a.set _1}, ponieważ przy zmianie wejścia (inlet), stare musi zostać odpięte.
# Algorytm sprawdzający cykle również bazuje na tym założeniu.
#
#  let:outpot ==weakref==> pot:outlet ==weakref==> let
#  let:inpot ==hardref==> pot:inlet ==hardref==> let
#
require "weakref"

module Ruby2D
  module CommunicatingVesselSystem
    def pot(value = nil, unique: true, pull: true)
      return value if !unique && v.is_a?(Pot)

      location = Pot.debug ? caller(1..1).first : nil
      BasicPot.new(pull:, location:).let value
    end

    def compot(*v, pull: true, &block)
      p1 = CommunicatingVesselSystem.pot
      p2 = CommunicatingVesselSystem.pot(pull:)
      CommunicatingVesselSystem.let(*v, p1, BasicPot.new(p2), &block)._connect(p2, pull: false)
      p2._recent = true
      location = Pot.debug ? caller(1..1).first : nil
      Compot.new(p1, p2, location:)
    end

    def arrpot(pull: true, &block)
      p1 = CommunicatingVesselSystem.pot []
      p2 = CommunicatingVesselSystem.pot(pull:)
      p3 = CommunicatingVesselSystem.pot pull: true
      block ||= proc { _1 }
      CommunicatingVesselSystem.let(p1) do |pots|
        pots = block.call(Array(pots))
        CommunicatingVesselSystem.let(*pots){|*a| a} >> p2
        pots
      end >> p3
      location = Pot.debug ? caller(1..1).first : nil
      Arrpot.new(p1, p2, p3, location:)
    end

    def let(*inpot, &)
      inpot = inpot.map do |i|
        case i
        when Pot then i
        when Let then i.pot
        else BasicPot.new.let(i)
        end
      end
      Let.new(inpot, &)
    end

    def let_if(a, b, c)
      let a, b, c do |av, bv, cv|
        av ? bv : cv
      end
    end

    class Let
      class DuplicatedConnectionError < StandardError
      end

      class DisconnectedLetUpdate < StandardError
      end

      def initialize(inpot, &block)
        @function = block
        @inpot = inpot
        @connected = false
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
        return copy >> target if @connected

        case target
        when Pot
          _connect target
        when Let
          _connect target.inpot # co z funkcją z jednym wejściem
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
        CommunicatingVesselSystem.arrpot { _1.map(&).compact.flatten } << self
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

        ao = Array(outpot)
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
        oc = Array(outpot).compact
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
        Array(_outpot).compact.each { _1._set_inlet(false) }
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

    class Pot
      @@debug = false
      def self.debug=(debug)
        @@debug = debug
      end

      def self.debug = @@debug

      def as(&)
        Let.new([self], &)
      end

      def >>(target)
        CommunicatingVesselSystem.let(self) >> target
        return self
      end

      def <<(source)
        if source.is_a? Let
          source >> self
        elsif source.is_a? Pot
          CommunicatingVesselSystem.let(source) >> self
        else
          self.set source
        end
        return self
      end

      def affect(affected)
        if affected.is_a? Pot
          test = proc { _1 == affected }
        elsif affected.is_a? Let
          inpot = affected.inpot
          test = proc { inpot.include? _1 }
        else
          return false
        end
        return _dfs(direction: :out, exclude_root: false).any?(&test)
      end

      def self.print_inpot_tree(pt)
        pt._dfs(direction: :in).map do |pt1, d|
          p (">" * d) + pt1.inspect
        end
      end

      def arrpot(&)
        CommunicatingVesselSystem.arrpot { _1.map(&).compact.flatten } << self
      end

      def to_ary
        return [self]
      end

      def self._dfs_next_seed
        @@dfs_seed = @@dfs_seed.next
      end

      @@dfs_seed = 0
      def _dfs(depth = 0, direction: :in, deeper_later: true, exclude_root: true, seed: nil)
        if seed
          return [] if @dfs_seed == seed

          @dfs_seed = seed
        else
          @dfs_seed = seed = Pot._dfs_next_seed
        end
        Enumerator.new do |e|
          e.yield(self, depth) if deeper_later && !exclude_root
          if direction == :in
            _inpot.each do |ip|
              ip._dfs(depth + 1, direction:, deeper_later:, exclude_root: false, seed:).each do |id, dp|
                e.yield(id, dp)
              end
            end
          elsif direction == :out
            _outlet.each do |ol|
              Array(ol._outpot).compact.each do |op|
                op._dfs(depth + 1, direction:, deeper_later:, exclude_root: false, seed:).each do |od, dp|
                  e.yield(od, dp)
                end
              end
            end
          end
          e.yield(self, depth) if !deeper_later && !exclude_root
        end
      end

      def _dfs_path(direction: :in, seed: nil)
        path = []
        Enumerator.new do |e|
          _dfs(direction:, exclude_root: false, seed:).each do |pt, d|
            path[d] = pt
            e.yield(path[..d])
          end
        end
      end
    end

    class BasicPot < Pot
      def initialize(value = nil, pull: true, recent: true, location: nil)
        super()
        @inlet = nil
        @outlet = []
        @value = value
        @recent = recent
        @pull = pull
        @location = location
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
        if @location
          "BasicPot:#{object_id}(#{@location})"
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
          pull_down = _outlet.map { |ol| Array(ol._outpot).compact.map { _1._outdate }.reduce([], :+) }.reduce([], :+)
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

    class Compot < Pot
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
          "Compot:#{object_id}(#{@location})"
        else
          "Compot:#{object_id}(" + 
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
        @inpot._inlet
      end

      def _inpot
        @inpot._inlet ? @inpot._inlet._inpot : []
      end

      def _add_outlet(let)
        @outpot._add_outlet(let)
      end

      def _delete_outlet(let)
        @outpot._delete_outlet(let)
      end

      def _compot_inpot
        @inpot
      end

      def _compot_outpot
        @outpot
      end
    end

    class Arrpot < Compot
      def initialize(inpot, outpot, drainpot, location: nil)
        super(inpot, outpot, location:)
        @drain = drainpot
      end

      def set(value = nil, &mod)
        value = mod.call(@drain.get, value) if mod
        @inpot.set value
        return self
      end

      def inspect
        if @location
          "Arrpot:#{object_id}(#{@location})"
        else
          "Arrpot:#{object_id}(" +
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
