open List
open Array2

val absorbing = [ (1,3,~100.0), (0,3,100.0) ] (* List of (row,col,value) for absorbing states *)
val barriers  = [ (1,1) ] (* List of invalid cells *)
val cols      = 300       (* Number of columns in grid *)
val cost      = 4.0       (* Cost of a move *)
val delta     = 0.01  (* Delta for use in comparing grids *)
val gamma     = 1.0       (* Gamma value for diminishing values *)
val pforward  = 0.8       (* Probability of moving in desired direction *)
val pleft     = 0.1       (* Prob. of moving 90 degrees left *)
val pright    = 0.1       (* Prob. of moving 90 degrees right *)
val pback     = 0.0       (* Prob. of moving in reverse *)
val rows      = 300       (* Number of rows in grid *)

type Grid = real array
datatype direction = N | E | S | W

fun forwardDir d  = d
fun leftDir d     = case d of N => W | E => N | S => E | W => S
fun rightDir d    = case d of N => E | E => S | S => W | W => N
fun oppositeDir d = case d of N => S | E => W | S => N | W => E
fun directionProbabilities d =
    [ (d, pforward), (oppositeDir d, pback), (leftDir d, pleft), (rightDir d, pright) ]

fun initGrid () =
    let val grid = array(rows,cols,0.0)
        fun updateGrid [] = ()
          | updateGrid ((r,c,v)::xs) = (update(grid,r,c,v); updateGrid xs)
    in
      ( updateGrid absorbing; grid )
    end

fun elem x xs         = exists (fn e => e = x) xs
fun isAbsorbing (r,c) = elem (r,c) (map (fn (r,c,v) => (r,c)) absorbing)
fun isBarrier (r,c)   = elem (r,c) barriers

fun validCoords (r,c) =
    r >= 0 andalso r < rows andalso c >= 0 andalso c < cols andalso (not (isBarrier(r,c)))

fun move d (r,c) =
    let val (r',c') = case d of N => (~1,0) | E => (0,1) | S => (1,0) | W => (0,~1)
        val p' = (r+r',c+c')
    in
      if validCoords p' then p' else (r,c)
    end

fun nextPosition (r,c) = if c<(cols-1) then (r,c+1) else if r<(rows-1) then (r+1,0) else (~1,~1)

fun maxArg ([]:real list) m = m
  | maxArg (x::xs) m        = if x>m then maxArg xs x else maxArg xs m

(* Compute the next value for a cell *)
fun newValue (grid:Grid) (r,c) =
    let fun moveVal d (r,c) =
            let fun reward (d,prob) = let val (r',c') = move d (r,c) in prob * sub(grid,r',c') end
                val terms = map reward (directionProbabilities d)
            in
              (foldr op+ 0.0 terms) - cost
            end
        val args = map (fn d => moveVal d (r,c)) [ N, E, S, W ]
    in
      (maxArg args 0.0) * gamma
    end

(* Perform a single value iteration on the entire grid *)
fun valueIteration (grid:Grid) (grid':Grid) (~1,~1) = grid'
  | valueIteration (grid:Grid) (grid':Grid) (r,c) =
    if isBarrier(r,c) then valueIteration grid grid' (nextPosition(r,c))
    else if isAbsorbing(r,c) then ( update(grid',r,c,(sub(grid,r,c)));
                                    valueIteration grid grid' (nextPosition(r,c)) )
    else ( update(grid',r,c,(newValue grid (r,c)));
           valueIteration grid grid' (nextPosition(r,c)))

fun equal (grid:Grid) (grid':Grid) =
    let fun equal_r (g:Grid) (g':Grid) (~1,~1) = true
          | equal_r (g:Grid) (g':Grid) (r,c) =
            if (abs (sub(g,r,c) - sub(g',r,c))) < delta
            then equal_r g g' (nextPosition(r,c))
            else false
    in
      equal_r grid grid' (0,0)
    end

(* Perform value iteration until convergence *)
fun mdp (grid:Grid) =
    let
      val grid' = valueIteration grid (array(rows,cols,0.0)) (0,0)
    in
      if (equal grid grid') then grid else (mdp grid')
    end
