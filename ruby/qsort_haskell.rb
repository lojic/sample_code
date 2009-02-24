require 'pp'

def qsort arr
  return [] if arr.length == 0
  x = arr.shift
  less, more = arr.partition {|e| e < x }
  qsort(less) + [x] + qsort(more)
end

x = [3,6,5,9,2,3,1,0]
pp qsort(x)
