open List

fun cartesian [] = []
  | cartesian ([x]) = map (fn e => [e]) x
  | cartesian (x::xs) =
    let val tailCross = cartesian xs
    in foldr (fn (tc,l) => ) [] x end

fun cartesian2 [] = []
  | cartesian2 ([x]) = map (fn e => [e]) x
  | cartesian2 (x::xs) =
    let val tailCross = cartesian2 xs
    in foldr (fn (x',result) => 
        foldr (fn (tc,l) => (x'::tc) :: l ) result tailCross) [] x
    end

(*
val x = cartesian [
  [1,2,3,4,5,6,7,8,9,10],
  [1,2,3,4,5,6,7,8,9,10],
  [1,2,3,4,5,6,7,8,9,10],
  [1,2,3,4,5,6,7,8,9,10],
  [1,2,3,4,5,6,7,8,9,10],
  [1,2,3,4,5,6,7,8,9,10],
  [1,2,3,4,5,6,7,8,9,10]
]

*)
