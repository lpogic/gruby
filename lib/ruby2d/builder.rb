module Ruby2D
  module Builder
    def builder name, &b
      define_method "new_#{name}", &b
      define_method "#{name}!" do |*a, **na, &bb|
        o = send "new_#{name}", *a, plan_dim: false, **na.except(:x, :y, :width, :height)
        append(o, **na)
        behalf o, &bb if bb
        return o
      end
    end
  end
end