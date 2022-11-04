class Foo
    def xd
        p "XD"
    end
end

o = Foo.new

def o.template
    xd
end

o.template
