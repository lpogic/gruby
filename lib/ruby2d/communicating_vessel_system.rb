# SYSTEM ZMIENNYCH POWIĄZANYCH TYPU PUSH

# Zmienne wyjściowe (outpot) muszą być podane jawnie, a nie jako efekt uboczny np {@a.set _1}, ponieważ przy zmianie wejścia (inlet), stare musi zostać odpięte.
# Nie dotyczy połączeń stałych jak w compot, arrpot
#
#  let:outpot ==weakref==> pot:outlet ==weakref==> let
#  let:inpot ==hardref==> pot:inlet ==hardref==> let
#
require 'weakref'

module Ruby2D
  module CommunicatingVesselSystem
    def pot(v = nil, unique: true, pull: true)
      return v if not unique and v.is_a?(Pot)

      location = Pot.debug ? caller[0] : nil
      BasicPot.new(pull: pull, location: location).let v
    end

    def compot(*v, pull: true, &block)
      p1 = CommunicatingVesselSystem.pot
      p2 = CommunicatingVesselSystem.pot pull: pull
      CommunicatingVesselSystem.let(*v, p1, BasicPot.new(p2), &block).apply_outpot(p2, pull: false)
      p2.recent = true
      location = Pot.debug ? caller[0] : nil
      Compot.new(p1, p2, location: location)
    end

    def arrpot(pull: true, &block)
      p1 = CommunicatingVesselSystem.pot []
      p2 = CommunicatingVesselSystem.pot pull: pull
      p3 = CommunicatingVesselSystem.pot pull: true
      block ||= proc { _1 }
      CommunicatingVesselSystem.let(p1) do |pots|
        pots = [] if pots.nil?
        pots = block.(pots.array)
        CommunicatingVesselSystem.let(*pots) { |*a| [a] } >> p2
        [pots]
      end >> p3
      location = Pot.debug ? caller[0] : nil
      Arrpot.new(p1, p2, p3, location: location)
    end

    def let(*inpot, out: nil, &block)
      inpot = inpot.map do |i|
        case i
        when Pot then i
        when Let then i.pot
        else BasicPot.new.let(i)
        end
      end
      if block_given?
        if out.nil?
          return Let.new(inpot, &block)
        else
          l = Let.new(inpot, &block)
          l.apply_outpot(*out)
          return l
        end
      else
        return Let.new(inpot) do |*v| v end
      end
    end

    def let_debug(*inpot, out: nil, &block)
      inpot = inpot.map { _1.is_a?(Pot) ? _1 : BasicPot.new.let(_1) }
      if block_given?
        if out.nil?
          return LetDebug.new(inpot, caller, &block)
        else
          l = LetDebug.new(inpot, caller, &block)
          l.apply_outpot(*out)
          return l
        end
      else
        return LetDebug.new(inpot, caller) do |*v| v end
      end
    end

    class Let
      def initialize(inpot, &block)
        @function = block
        @inpot = inpot
        @outpot = []
      end

      attr_reader :function

      def inspect
        "Let:#{self.object_id} @inpot=#{@inpot.map { "Pot:" + _1.object_id.to_s }} @outpot=#{@outpot.map { "Pot:" + _1.object_id.to_s }} @function=#{@function}"
      end

      def copy
        Let.new @inpot, &@function
      end

      # dla funkcji agregujących np. let(*xes).max,    let(a, b, c).max
      def method_missing(m, *a, &b)
        if Array.method_defined? m
          __compose(m, *a, &b)
        else
          super
        end
      end

      def __compose(m, *arg, &b)
        if @function
          Let.new(@inpot) do |*a|
            @function.call(*a).array.send(m, *arg, &b)
          end
        else
          Let.new(@inpot) do |*a|
            a.send(m, *arg, &b)
          end
        end
      end

      def as(&b)
        if @function
          Let.new(@inpot) do |*a|
            b.(*@function.call(*a))
          end
        else
          Let.new(@inpot, &b)
        end
      end

      def apply_outpot(*outpot, pull: true)
        raise "Connected" if @connected
        loop_test *outpot
        od = outpot.map do
          _1.set_inlet self
          _1.outdate
        end.reduce(:+)
        @outpot += outpot.map { WeakRef.new _1 }
        if not @connected
          @inpot.each { _1.add_outlet(self) }
          @connected = true
        end
        od.each(&:get) if pull
      end

      def inpot = @inpot

      def outpot
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
        o
      end

      def loop_test *outpot
        seed = Pot.dfs_next_seed
        path_found = inpot.map do |i|
          i.dfs_path(seed: seed).find do |path|
            outpot.include?(path.last)
          end
        end.find(&:itself)
        raise "Pot loop detected:\n" + path_found.map { _1.inspect }.join("\n") if path_found
      end

      def >>(that)
        return copy >> that if @connected
        case that
        when Pot
          apply_outpot that
        when Let
          apply_outpot *that.inpot
        when Array
          apply_outpot *that
        else raise "Invalid right side"
        end
        self
      end

      def unlock
        @locked = false
      end

      def update
        return if @closed

        outpot = self.outpot
        oc = outpot.compact
        if oc.empty?
          cancel
          return
        end
        oc.each { _1.recent = true }
        result = get.array
        if outpot.size > 1
          result.zip(outpot).each { |r, o| o.__set r if not o.nil? }
        else
          outpot[0].__set result[0]
        end
        result
      end

      def outdate
        outpot.compact.map { _1.outdate }.reduce([], :+)
      end

      def get
        i = @inpot.map(&:get)
        @function ? @function.call(*i) : i.size > 1 ? i : i[0]
      end

      def close
        @closed = true
      end

      def open(open = true)
        raise "Canceled let open" if open and (!@function or !@outpot)

        @closed = !open
      end

      def cancel
        @inpot.each { |i| i.delete_outlet(self) }
        @inpot = []
        @function = nil
        @closed = true
      end

      def detach
        @inpot.each { |i| i.delete_outlet(self) }
        @connected = false
        outpot.each { _1.set_inlet(false) }
        @outpot = []
      end

      def delete_outpot(to_delete)
        @outpot = @outpot.map { _1.nil? || !_1.weakref_alive? || _1.__getobj__ == to_delete ? nil : _1 }
        cancel if @outpot.compact.empty?
      end

      def pot
        pt = BasicPot.new
        self >> pt
        pt
      end

      def pots(count)
        Array.new(count) { BasicPot.new }.map do |pt|
          self >> pt
          pt
        end
      end

      def arrpot(&b)
        CommunicatingVesselSystem.arrpot { _1.map(&b) } << self
      end
    end

    class LetDebug < Let
      def initialize(inpot, caller, &block)
        @function = block
        @inpot = inpot
        @outpot = []
        @caller = caller
      end

      attr_reader :caller
    end

    class Pot
      @@debug = false
      def self.debug=(debug)
        @@debug = debug
      end

      def self.debug = @@debug

      def >>(pt)
        CommunicatingVesselSystem.let(self) >> pt
        self
      end

      def <<(obj)
        obj = CommunicatingVesselSystem.let(obj) if not obj.is_a? Let
        obj >> self
        self
      end

      def self.dfs_next_seed
        @@dfs_seed = @@dfs_seed.next
      end

      @@dfs_seed = 0
      def dfs(depth = 0, direction: :in, deeper_later: true, exclude_root: true, seed: nil)
        if seed
          return [] if @dfs_seed == seed

          @dfs_seed = seed
        else
          @dfs_seed = seed = Pot.dfs_next_seed
        end
        Enumerator.new do |e|
          e.yield(self, depth) if deeper_later and not exclude_root
          if direction == :in
            if inlet
              inlet.inpot.each do |ip|
                ip.dfs(depth + 1, direction: direction, deeper_later: deeper_later, exclude_root: false, seed: seed).each do |id, dp|
                  e.yield(id, dp)
                end
              end
            end
          elsif direction == :out
            outlet.each do |ol|
              ol.outpot.compact do |op|
                op.dfs(depth + 1, direction: direction, deeper_later: deeper_later, exclude_root: false, seed: seed).each do |od, dp|
                  e.yield(od, dp)
                end
              end
            end
          end
          e.yield(self, depth) if not deeper_later and not exclude_root
        end
      end

      def dfs_path(direction: :in, seed: nil)
        path = []
        Enumerator.new do |e|
          dfs(direction: direction, exclude_root: false, seed: seed).each do |pt, d|
            path[d] = pt
            e.yield(path[..d])
          end
        end
      end

      def print_inpot_tree
        dfs(direction: :in).map do |pt, d|
          p " " * d + pt.inspect
        end
      end

      def arrpot(&b)
        CommunicatingVesselSystem.arrpot { _1.map(&b) } << self
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

      def inspect
        if @location
          "pot #{@location}"
        else
          "BasicPot:#{self.object_id} @recent=#{@recent} @value=#{@value.inspect} @inlet=#{
            @inlet ? "Let:" + @inlet.object_id.to_s : "nil"} @outlet=#{@outlet.map { "Let:" + _1.object_id.to_s }}"
        end
      end

      def get
        update if not @recent
        @value
      end

      attr_accessor :recent, :value

      def nopull
        pull, @pull = @pull, false
        yield
        @pull = pull
      end

      def update
        @recent = true
        @inlet.update if @inlet
      end

      def outdate
        if @recent
          @recent = false
          pull_down = outlet.map { o = _1.outdate; p _1.function if o.nil?; o }.reduce([], :+)
          pull_down && !pull_down.empty? ? pull_down : @pull ? [self] : []
        else
          []
        end
      end

      def __set(value)
        @value = value
        @recent = true
      end

      def outlet
        o = []
        @outlet = @outlet.map do |wr|
          begin
            o << wr.__getobj__
            wr
          rescue
            nil
          end
        end.compact
        o
      end

      def set(value = nil, &mod)
        value = mod.call(get, value) if block_given?
        set_inlet(nil)
        od = outdate
        __set(value)
        od.each(&:get)
        self
      end

      def let(*v, &block)
        if block_given?
          l = Let.new(v.map { _1.is_a?(Pot) ? _1 : BasicPot.new.let(_1) }, &block)
        elsif v[0].is_a? Let
          l = v[0].copy
        elsif v[0].is_a? Pot
          l = Let.new(v)
        else
          return set(v[0])
        end
        l.apply_outpot(self)
        self
      end

      def as(&block)
        Let.new([self], &block)
      end

      alias value= set

      def set_inlet(inlet)
        @inlet.delete_outpot self if @inlet
        @inlet = inlet
      end

      def inlet
        @inlet
      end

      def dependent?
        return !!@inlet
      end

      def add_outlet(let)
        @outlet.append(WeakRef.new let) if not outlet.include? let
      end

      def delete_outlet(let)
        @outlet.delete_if { not _1.weakref_alive? or _1.__getobj__ == let }
      end
    end

    class Compot < Pot
      def initialize(inpot, outpot, location: nil)
        super()
        @inpot = inpot
        @outpot = outpot
        @location = location
      end

      def inspect
        if @location
          "compot #{@location}"
        else
          "Compot:#{self.object_id} @inpot=#{@inpot.inspect} @outpot=#{@outpot.inspect}]"
        end
      end

      def get
        @outpot.get
      end

      def value
        @outpot.value
      end

      def outlet
        @outpot.outlet
      end

      def update
        @inpot.update
      end

      def outdate
        @inpot.outdate
      end

      def recent=(recent)
        @outpot.recent = recent
      end

      def recent
        @outpot.recent
      end

      def __set(value)
        @inpot.__set value
      end

      def set(value = nil, &mod)
        value = mod.call(get, value) if block_given?
        @inpot.set value
        self
      end

      def let(*v, &block)
        @inpot.let(*v, &block)
        self
      end

      def as(&block)
        Let.new([self], &block)
      end

      alias value= set

      def set_inlet(inlet)
        @inpot.set_inlet inlet
      end

      def inlet
        @inpot.inlet
      end

      def dependent?
        @inpot.dependent?
      end

      def lock_inlet(lock = true)
        @inpot.lock_inlet lock
      end

      def unlock_inlet
        @inpot.unlock_inlet
      end

      def add_outlet(let)
        @outpot.add_outlet(let)
      end

      def delete_outlet(let)
        @outpot.delete_outlet(let)
      end

      def inpot = @inpot
      def outpot = @outpot
    end

    class Arrpot < Compot
      def initialize(inpot, outpot, drainpot, location: nil)
        super(inpot, outpot, location: location)
        @drain = drainpot
      end

      def inspect
        if @location
          "arrpot #{@location}"
        else
          "Arrpot:#{self.object_id} @inpot=#{@inpot.inspect} @outpot=#{@outpot.inspect}]"
        end
      end

      def get_raw
        @drain.get
      end

      def set(value = nil, &mod)
        value = mod.call(get_raw, value) if block_given?
        @inpot.set value
        self
      end

      def map(&b)
        arrpot << self.as { _1.map(&b) }
      end

      # dla funkcji agregujących np. let(*xes).max,    let(a, b, c).max
      def method_missing(m, *a, &b)
        if Array.method_defined? m
          as { _1.send(m, *a, &b) }
        else
          super
        end
      end
    end
  end
end

class Class
  def cvs_reader(*a)
    make_reader = proc do |n|
      ns = n.split(':')
      ns[1] ||= ns[0]
      pt = "c = defined?(self._cvs_#{ns[0]}) ? self._cvs_#{ns[0]} : @#{ns[0]}"
      self.class_eval("def #{ns[1]}(&b); #{pt}; block_given? ? c.as(&b) : c;end")
    end

    a.each do |n|
      if n.is_a? Array
        n.each { make_reader.(_1.to_s) }
      else
        make_reader.(n.to_s)
      end
    end
  end
end
