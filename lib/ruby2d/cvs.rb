class Class
  def cvs_reader(*a)
    make_reader = proc do |n|
      ns = n.split(':')
      ns[1] ||= ns[0]
      pt = "c = defined?(self._cvs_#{ns[0]}) ? self._cvs_#{ns[0]} : @#{ns[0]}"
      self.class_eval("def #{ns[1]}(&b); #{pt}; block_given? ? c.as(&b) : c;end")
    end

    a.each do |n|
      if n.is_a? Array
        n.each { make_reader.(_1.to_s) }
      else
        make_reader.(n.to_s)
      end
    end
  end
end
