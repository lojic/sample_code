def quicksort x, l, u
  return unless l < u
  m = l
  (l+1 .. u).each do |i|
    if x[i] < x[l]
      ++m
      x[m], x[i] = x[i], x[m]
    end
  end
  x[l], x[m] = x[m], x[l]
  quicksort(x, l, m-1)
  quicksort(x, m+1, u)
end

n = 3000
x = Array.new(n)
n.times {|i| x[i] = rand(n) }
quicksort x, 0, x.length-1
puts "first=#{x[0]}, middle=#{x[n/2]}, last=#{x[-1]}" 

