val l = [1,2,3,4,5]

fun f x = x * x
fun g x = x + 1

map f l                 (* [1,4,9,16,25] *)

map g l                 (* [2,3,4,5,6] *)

((map f) o (map g)) l   (* [4,9,16,25,36] *)

map (f o g) l           (* [4,9,16,25,36] *)
*)
