module Ruby2D
  class Album < Cluster
    n = note text: 'DODODS'
    n1 = note x: 300, y: 300, editable: false
    ns = note_support
    sgs = arrpot << (1..50).to_a
    on n.keyboard_current do |kc|
      ns.accept_subject nil unless kc
    end
    n.on :click do
      if ns.subject == n
      # ns.accept_subject nil
      else
        ns.accept_subject n
        ns.suggestions << sgs
        ns.on_option_selected do |o|
          n.text << n.text.get.then { _1 + (_1 != '' ? ', ' : '') + o.to_s }
          sgs.set do
            _1.delete(o)
            _1
          end
          # n.text << o
          # ns.accept_subject nil
        end
      end
    end
    n.on :key_type do |e|
      if e.key == 'down' || e.key == 'up'
        if ns.subject == n
          ns.hover_down if e.key == 'down'
          ns.hover_up if e.key == 'up'
        else
          ns.accept_subject n
          ns.suggestions << sgs
          ns.on_option_selected do |o|
            n.text.set o
            ns.accept_subject nil
          end
        end
      end
    end
    n.on :key_down do |e|
      ns.press_hovered if e.key == 'return' && (ns.subject == n)
    end
    n.on :key_up do |e|
      ns.release_pressed if e.key == 'return' && (ns.subject == n)
    end
    on n1.keyboard_current do |kc|
      if kc
        ns.accept_subject n1
        ns.suggestions.set %w[1 2 3]
        ns.on_option_selected do |o|
          n1.text.set o
          ns.accept_subject nil
        end
      else
        ns.accept_subject nil
      end
    end
  end
end
