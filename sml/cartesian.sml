open List

(*
fun cartesian1 [] = []
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
*)

(* Compute cartesian product of a list of lists
   cartesian [[1,2],[3,4],[5,6]] =>
   [[1, 3, 5], [1, 3, 6], [1, 4, 5], [1, 4, 6], [2, 3, 5], ... ] *)
fun cartesian [] = []
  | cartesian ([x]) = map (fn e => [e]) x
  | cartesian (x::xs) =
    let val tailCross = cartesian xs
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
