def hanoi n, from=1, to=2, extra=3
  return if n < 1
  hanoi n-1, from, extra, to
  puts "move #{from} -> #{to}"
  hanoi n-1, extra, to, from
end

hanoi 4 
