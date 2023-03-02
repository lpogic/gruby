def foo(*a, &b)
  b[a]
end

a = [1,2,3]
foo(*a){p _1}