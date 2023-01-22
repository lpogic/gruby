module Ruby2D
    class RubyNote < Note
        def init(text: '', **narg)
            super
            on_key 'return' do
                begin
                    t = self.text.get
                    select_all
                    paste eval(t).to_s
                rescue SyntaxError
                end
            end
        end
    end
end