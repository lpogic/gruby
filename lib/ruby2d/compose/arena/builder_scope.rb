module Ruby2D
  module BuilderScope
    @@build_stack = []

    def build_stack
      @@build_stack
    end

    def push_build_stack(element)
      @@build_stack.push element
      yield
      @@build_stack.pop
    end


    def send_current(m)
      @@build_stack.reverse.find{_1.respond_to? m}
    end

    def builder_method *sym
      sym.each do |s|
        rs = "raw_builder_#{s}".to_sym
        alias_method rs, s
        define_method s do |*a, **na, &b|
          sc = self.class.send_current s
          (sc || self).send(rs, *a, **na, &b)
        end
      end
    end
  end
end