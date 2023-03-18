module Ruby2D
  module BlockScope
    @masking_activated = false
    @masking_methods = []
    @scoping_activated = false
    @scoping_methods = []

    def masking_active!(active = true)
      active_before = @masking_activated
      @masking_activated = active
      return active_before
    end

    def masking *names
      self._masking_methods |= names.flatten
      if block_given?
        active_before = masking_active!
        yield
        masking_active! active_before
      end
    end

    def masking_methods
      m = superclass.respond_to?(:masking_methods) ? superclass.masking_methods : []
      m |= @masking_methods if @masking_methods
      return m
    end

    def scoping_active!(active = true)
      active_before = @scoping_activated
      @scoping_activated = active
      return active_before
    end

    def scoping *names
      if block_given?
        active_before = scoping_active!
        yield
        scoping_active! active_before
      end
      names = names.flatten - self._scoping_methods
      self._scoping_methods += names
      sab = scoping_active! false
      
      names.each do |s|
        os = "original_#{s}".to_sym
        mab = masking_active! false
        alias_method os, s
        masking_active! mab
        define_method s do |*a, **na, &b|
          r = self.send(os, *a, **na)
          return b ? host.scope(r, &b) : r
        end
      end
      
      scoping_active! sab
    end

    def scoping_methods
      m = superclass.respond_to?(:scoping_methods) ? superclass.scoping_methods : []
      m |= @scoping_methods if @scoping_methods
      return m
    end

    def method_added(name)
      if @masking_activated
        masking name
      else
        _masking_methods.delete name
      end

      if @scoping_activated
        scoping name
      else
        _scoping_methods.delete name
      end
    end

    class ScopeValet

      def initialize host
        @host = host
        @scopes = []
      end

      def method_missing(name, *a, **na, &b)
        @host.send name, *a, **na, &b
      end
    
      def respond_to_missing?(name, include_private = false)
        @host.respond_to? name
      end

      def scope(mask, &b)
        _push mask
        r = mask.scoped &b
        _pop
        return r
      end

      private

      def _push top
        @scopes.push(
          (top.class.respond_to?(:masking_methods) ? top.class.masking_methods : top.public_methods(true)).map do |im|
            original_method = nil
            masking_method = nil
            self_method = nil
            if @host.respond_to? im
              original_method = @host.method(im)
              if respond_to? im
                self_method = self.method(im)
              end
              self.define_singleton_method original_method.name do |*a, **na, &b|
                original_method.call(*a, **na, &b)
              end
            end
            @host.define_singleton_method im.name do |*a, **na, &b|
              top.send(im, *a, **na, &b)
            end
            masking_method = @host.singleton_method(im)
            {original: original_method, masking: masking_method, self: self_method, name: masking_method.name}
          end
        )
      end

      def _pop
        @scopes.pop.each do |mm|
          if @host.singleton_method(mm[:masking].name) == mm[:masking]
            if mm[:original]
              @host.define_singleton_method mm[:original].name, mm[:original]
              if mm[:self]
                define_singleton_method mm[:self].name, mm[:self]
              else
                self.singleton_class.remove_method mm[:original].name
              end
            else
              @host.singleton_class.remove_method mm[:masking].name
            end
          end
        end
      end
    end

    module Includes

      def host
        @scope_valet || self
      end

      def scope(mask, &b)
        if @scope_valet
          @scope_valet.scope(mask, &b)
        else
          @scope_valet = ScopeValet.new self
          @scope_valet.scope(mask, &b)
          @scope_valet = nil
        end
      end

      def scoped
        yield self
      end
    end

    def self.extended(mod)
      mod.include Includes
      super
    end

    private

    def _masking_methods
      @masking_methods || []
    end

    def _masking_methods=(mm)
      @masking_methods = mm
    end

    def _scoping_methods
      @scoping_methods || []
    end

    def _scoping_methods=(sm)
      @scoping_methods = sm
    end
  end
end