# frozen_string_literal: true

# Ruby2D::Entity

module Ruby2D
  module Entity
    include CVS
    include Planned
    attr_accessor :parent, :nanny

    def anc(filter = nil)
      case filter
      when nil then @parent
      when Class then @parent.is_a?(filter) ? @parent : @parent.anc(filter)
      when Symbol then @parent.names.include?(filter) ? @parent : @parent.anc(filter)
      else filter.to_proc.call(@parent) ? @parent : @parent.anc(filter)
      end
    end

    def names
      @names ||= []
    end

    def name(n)
      if n.is_a? Enumerable
        n.each { name _1 }
      elsif n.is_a? Symbol
        names << n
      end
    end

    def desc(filter = nil)
      []
    end

    def emit(type, event = nil)
    end

    def contains?(x, y)
      false
    end

    def accept_mouse(e)
      contains?(e.x, e.y) ? self : nil
    end

    def lineage
      l = [self]
      l = @parent.lineage + l if @parent
      return l
    end

    def window = parent.window
  end
end