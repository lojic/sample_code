require 'pp'

class Array
  alias_method :orig_push, :push
  def push obj
    orig_push(obj)
    if block_given?
      yield self
      pop
    end
  end
end

def valid? stack
  q2 = stack.length - 1
  (0..stack.length-2).each do |q1|
    return false if stack[q1] == stack[q2] ||
      (q1-q2).abs == (stack[q1]-stack[q2]).abs
  end
end

def queens stack, n
  if n == 8
    #pp stack
  else
    (1..8).each do |rank|
      stack.push(rank) {|s| queens(s, n+1) if valid?(s) }
    end
  end
end

queens [], 0
