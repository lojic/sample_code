require 'pp'

def min a,b
  a < b ? a : b
end

def lcp str, a, b
  n = min(str.length - a, str.length - b)
  n = min(n, (a-b).abs) 
  0.upto(n) do |i|
    if str[a+i] != str[b+i]
      return i
    end
  end
  return n
end

def print_suffixes str, ary
  ary.each do |i|
    puts str[i, str.length - i]
  end
end

def lrs str
  # Create N suffixes
  len = str.length
  suffixes = Array.new(len) {|i| i }
  print_suffixes str, suffixes
  puts '-'*10

  # Sort them
  suffixes = suffixes.sort do |a,b|
    str[a, len-a] <=> str[b, len-b]
  end

  print_suffixes str, suffixes
  puts '-'*10

  # Compare adjacent suffixes
  lrs = ""
  0.upto(suffixes.length - 2) do |i|
    n = lcp(str, suffixes[i], suffixes[i+1])
    lrs = str[suffixes[i], n] if n > lrs.length
  end

  return lrs
end

str = STDIN.read
puts "Input length    : #{str.length}"
result = lrs(str)
puts "Length of result: #{result.length}"
puts '-'*25
puts lrs(str)
