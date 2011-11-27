require 'pp'

N = 11

def push_with_block stack, obj
  stack.push(obj)
  yield stack
  stack.pop
end

def valid? stack
  q2 = stack.length - 1
  (0..stack.length-2).each do |q1|
    return false if stack[q1] == stack[q2] ||
      (q1-q2).abs == (stack[q1]-stack[q2]).abs
  end
end

def queens stack, n
  if n == N
    #pp stack
  else
    (1..N).each do |rank|
      push_with_block(stack, rank) {|s| queens(s, n+1) if valid?(s) }
    end
  end
end

queens [], 0
