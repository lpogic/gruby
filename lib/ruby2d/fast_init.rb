module Ruby2D
    module FastInit
    end
end

class Class
    def fast_init(*una, accessor: false, reader: false, **na)
        class_eval("def initialize(#{(una.map { _1.to_s + ':' } + na.map { |k, v| k.to_s + ':' + v.to_s }).join(',')});" +
            "#{(una + na.keys).map { "@#{_1} = #{_1};" }.join}end")
        attr_accessor(*una) if accessor
        attr_reader(*una) if reader and !accessor
    end
end