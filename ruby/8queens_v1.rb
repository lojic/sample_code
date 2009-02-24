N = 8

def valid? stack
  q2 = stack.length - 1
  (0..stack.length-2).each do |q1|
    return false if stack[q1] == stack[q2] ||
      (q1-q2).abs == (stack[q1]-stack[q2]).abs
  end
end

def queens stack, n
  if n == N
    puts "[ #{stack.join(', ')} ]"
  else
    (1..N).each do |rank|
      stack.push(rank)
      queens(stack, n+1) if valid?(stack)
      stack.pop
    end
  end
end

queens [], 0
