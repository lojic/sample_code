fun combinations (0, _)    = [[]]
  | combinations (_, [])   = [[]]
  | combinations (m, h::t) = map (fn y => h :: y) (combinations (m-1, t)) @ combinations (m, t)

(*
fun permutations n [] = [[]]
  | permutations 0 _  = [[]]
  | permutations n s  =
    let
      fun remove item set =
          List.filter (fn e => (not (e = item))) set
    in
      List.concat (map (fn x => (map (fn p => x::p) (permutations (n-1) (remove x s)))) s)
    end
*)

(* permutations 2, [1,2,3] => [[1,2],[1,3],[2,1],[2,3],[3,1],[3,2]]  *)
fun permutations n [] = [[]]
  | permutations 0 _  = [[]]
  | permutations n s =
    let
      fun remove item set =
          List.filter (fn e => (not (e = item))) set
    in
      foldr (fn (s',result) =>
                foldr (fn (p,l) => (s'::p)::l) result (permutations (n-1) (remove s' s))) [] s
    end

fun upto (m,n) = if m>n then [] else m :: upto(m+1,n)
