require "weakref"

module Ruby2D
  module CommunicatingVesselSystem
    class Pot

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
          inpot = affected._inpot
          test = proc { inpot.include? _1 }
        else
          return false
        end
        return _dfs(direction: :out, exclude_root: false).any?(&test)
      end

      def self.inpot_tree(pt)
        pt._dfs(direction: :in).map do |pt1, d|
          (">" * d) + pt1.inspect
        end
      end

      def arrpot(&)
        CommunicatingVesselSystem.array_pot { _1.map(&).compact.flatten } << self
      end

      def to_a
        return [self]
      end

      @@dfs_seed = 0

      def self._dfs_next_seed
        @@dfs_seed = @@dfs_seed.next
      end

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
              ol._outpot.to_a.compact.each do |op|
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
  end
end
