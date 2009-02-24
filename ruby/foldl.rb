def foldl op, initial, sequence
  iter = lambda do |result, rest|
    if rest.empty?
      result
    else
      iter.call( op.call(result, rest[0]), rest[1..-1])
    end
  end
  iter.call(initial, sequence)
end

def foldl op, initial, sequence
  if sequence.empty?
    initial
  else
    foldl(op, op.call(initial, sequence[0]), sequence[1..-1])
  end
end

puts foldl(lambda {|x,y| x + y}, 1, [2, 3, 4])

