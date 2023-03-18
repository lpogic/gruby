module BlockScope
  class Receptionist
    def method_missing m, *a, **na, &b
      BlockScope.top_receiver(m).send(m, *a, **na, &b)
    end

    def respond_to_missing? m
      BlockScope.top_receiver(m) != nil
    end
  end

  @@call_stack = []
  @@receptionist = Receptionist.new

  def self.top_receiver(method_name)
    @@call_stack.reverse_each.find{ _1.respond_to? method_name}
  end

  def self.push *top
    @@call_stack.push *top
  end

  def self.pop n = 1
    @@call_stack.pop n
  end

  def self.top *top, &b
    push *top
    r = @@receptionist.instance_eval &b if block_given?
    pop top.size
    return r
  end
end

BlockScope.push Kernel
BlockScope.top "XD" do
  p self
end