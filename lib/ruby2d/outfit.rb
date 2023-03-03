module Ruby2D
  class Outfit
    include CVS

    def lay(seed = nil, **params)
      egg = self.class.new **self, **params
      if seed
        egg.seed = seed
        egg.hatch
      end
      egg
    end

    def hatch
    end

    def seed=(seed)
      @seed = seed
    end
  end

  class OutfitRoot
    def initialize(root)
      @root = root
    end

    def method_missing(name, *a)
      if name.end_with? '='
        _leaves(@root).each{|l| l.send name, *a}
      else
        r = @root[name]
        if r.is_a? Hash
          OutfitRoot.new r
        else
          r
        end
      end
    end

    def _leaves(root)
      Enumerator.new do |e|
        if root.is_a? Hash
          root.each_value do |v|
            _leaves(v).each do |l|
              e << l
            end
          end
        else
          e << root
        end
      end
    end

    def _dig(*path)
      path = path.map do |e|
        e.is_a?(Symbol) ? e : e.to_s.then{(_1[/^Ruby2D\:\:(.*)/, 1] || _1).downcase.to_sym}
      end
      @root.dig(*path)
    end
  end
end