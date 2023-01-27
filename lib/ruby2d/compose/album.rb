module Ruby2D
  class Album < Cluster

    attr_reader :note
    cvs_reader :options
    delegate note: %w[x y width height left right top left plan text]

    def init(options: nil, note_style: 'default', **plan)
      @note = new_note style: note_style, **plan
      care @note
      @options = pot << (options || [])

      on @note.keyboard_current do |kc|
        window.note_support.accept_subject nil unless kc
      end
      @note.on :click do
        ns = window.note_support
        if ns.subject == @note
          ns.accept_subject nil
        else
          ns.accept_subject @note
          ns.suggestions << @options
          ns.on_option_selected do |o|
            @note.text << @note.text.get.then { _1 + (_1 == '' ? '' : ', ') + o.to_s }
            @options.set do
              _1.delete(o)
              _1
            end
            ns.accept_subject nil
          end
        end
      end
      @note.on :key do |e|
        ns = window.note_support
        if e.key == 'down' || e.key == 'up'
          if ns.subject == @note
            ns.hover_down if e.key == 'down'
            ns.hover_up if e.key == 'up'
          else
            ns.accept_subject @note
            ns.suggestions << @options
            ns.on_option_selected do |o|
              @note.text.set o
              ns.accept_subject nil
            end
          end
        end
      end
      @note.on :key_down do |e|
        ns = window.note_support
        ns.press_hovered if e.key == 'return' && (ns.subject == @note)
      end
      @note.on :key_up do |e|
        ns = window.note_support
        ns.release_pressed if e.key == 'return' && (ns.subject == @note)
      end
    end
  end
end
