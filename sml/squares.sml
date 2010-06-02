fun iter (a,b) =
  if a <= b then (print(Int.toString(a*a) ^ " "); iter(a+1,b) )
  else print "\n";

iter(1,10);

fun iter 0 = ""
|   iter n = (iter(n-1); print(Int.toString(n*n) ^ " "); "\n");

print(iter 10000);
