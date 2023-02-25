module Ruby2D
  class Form < Cluster
    include Arena

    def init(margin: 8, **plan)
      @body = new_rectangle(**plan)
      @margin = pot << margin
      @nw = pot 80
    end

    delegate body: %w[fill plan x y width height left right top bottom]
    cvs_reader :margin

    def build(&b)
      rows color: 'green', round: 10, gap: [@margin] do
        b.call self
      end
    end

    def note_row(label, ruby: false)
      cr = send_current(__method__, label, ruby: ruby)
      return cr if cr
      a = nil
      cols gap: 5 do
        gap @margin
        rows width: @nw do text label, right: _1.right end
        a = ruby ? ruby_note : note
        gap @margin
      end
      a
    end

    def album_row(label, options)
      cr = send_current(__method__, label, options)
      return cr if cr
      a = nil
      cols gap: 5 do
        gap @margin
        rows width: @nw do text label, right: _1.right end
        a = album options
        gap @margin
      end
      a
    end

    def button_row(*labels)
      cr = send_current(__method__, *labels)
      return cr if cr
      btns = []
      cols gap: 5, right: self.right do
        gap @margin
        btns = labels.map { button _1 }
        gap @margin
      end
      btns
    end
  end
end
