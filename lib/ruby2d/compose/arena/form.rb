module Ruby2D
  class Form < Arena

    def init(margin: 6, **plan)
      @body = new_rect(**plan)
      @margin = pot << margin
      @note_col_width = pot 80
    end

    def outer_rows
      @rows ||= rows! color: 'navy', round: 10, gap: [@margin]
    end

    delegate body: %w[fill plan x y width height left right top bottom]
    cvsa :margin, :note_col_width
      
    def note_row!(name, label, ruby: false, &b)
      behalf outer_rows do |form|
        cols! gap: [form.margin, 5] do
          box! width: form.note_col_width do 
            text! let(label){ _1 + ":" }, right: right 
          end
          ruby ? ruby_note!(name:, &b) : note!(name:, &b)
        end
      end
    end

    def album_row!(name, label, options: [], &b)
      behalf outer_rows do |form|
        cols! gap: [form.margin, 5] do
          rows! width: form.note_col_width do 
            text! let(label){ _1 + ":" }, right: right 
          end
          album! options, name:, &b
        end
      end
    end

    def button_row!(*names, **labels, &b)
      behalf outer_rows do |form|
        cols! gap: [form.margin, 5], right: right do
          names.each{ button! _1, name: _1 }
          labels.each{|k, v| button! v, name: k }
          instance_exec &b if block_given?
        end
      end
    end
  end
end
