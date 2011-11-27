open List

datatype position = L | R
val numPositions = 2

type Row     = int
type Section = int
type Seat    = Section * Row * position
type Coord   = int * int
             
(* Compute an index for the position within a row *)
fun positionIndex L = 0
  | positionIndex R = 1

(* Convert an index within a row to a position *)                      
fun positionFromIndex 0 = L
  | positionFromIndex 1 = R
     
(* Convert a seat to a (row, col) coordinate *)
fun seatToCoord ((s,r,p):Seat) =
    (r-1, (s-1)*numPositions + positionIndex(p))

(* Convert a (row,col) coordinate to a seat *)
fun coordToSeat (row,col) =
    (col div numPositions + 1, row + 1, positionFromIndex (col mod numPositions))
    
(* original seat distance - simple Manhatten *)
fun oldseatDistance (s1:Seat) (s2:Seat) : int = 
    let val (r1,c1) = seatToCoord s1
        val (r2,c2) = seatToCoord s2
    in 
      abs(r1-r2) + abs(c1-c2)
    end

val numRows = 13
val numCols = 8

fun max a b = if a > b then a else b
fun min a b = if a < b then a else b

(* Compute the Manhatten distance between seats wrapping around
   horizontally and vertically *)
fun seatDistance (s1:Seat) (s2:Seat) : int =
    let val (r1,c1) = seatToCoord s1
        val (r2,c2) = seatToCoord s2
        val rDiff = abs(r1-r2)
        val cDiff = abs(c1-c2)
    in 
      (min rDiff (numRows - rDiff)) + 
      (min cDiff (numCols - cDiff))
    end
    
fun coordDistance (r1, c1) (r2, c2) =
    let         val rDiff = abs(r1-r2)
        val cDiff = abs(c1-c2)
    in 
      (min rDiff (numRows - rDiff)) + 
      (min cDiff (numCols - cDiff))
    end
    
(* Indicate whether x is an element of xs *)
fun elem x xs = exists (fn e => e = x) xs
fun upto (m,n) = if m>n then [] else m :: upto(m+1,n)

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
(* orig
fun sumDist (r,c) [] = 0
  | sumDist (r,c) ((r',c')::xs) = abs(r-r') + abs(c-c') + sumDist (r,c) xs  *)

fun sumDist (r,c) [] = 0
  | sumDist (r,c) ((r',c')::xs) = (coordDistance (r,c) (r',c')) + sumDist (r,c) xs
(*
fun qsort f [] = []
  | qsort f (x::xs) =
    let val smaller = filter (not o f x) xs
        val larger =  filter (f x) xs
    in qsort f smaller @ [x] @ qsort f larger end
*)
fun qsort f [] = []
  | qsort f (x::xs) =
    let val (larger, smaller) = List.partition (f x) xs
    in qsort f smaller @ [x] @ qsort f larger end
                                  
fun isLess ((_,_), a) ((_,_), b) = a < b
fun isMore ((_,_), a) ((_,_), b) = a > b

val reservedSeats = [
    (0,0),(0,1),  (* prophecy mic *)
    (12,0),(12,1), (* rear of section 1 *)
    (11,2),(11,3),(12,2),(12,3), (* rear of section 2 *)
    (12,6),(12,7) (* rear of section 4 *)
]

fun candidates pastSeats =
    let 
      val occupiedSeats = map seatToCoord pastSeats
      val allSeats = map (fn e => (hd e, hd (tl e))) (cartesian [ upto(0,numRows - 1), upto(0,numCols - 1) ])
      val emptySeats = filter (fn e => not (elem e occupiedSeats orelse elem e reservedSeats)) allSeats
      val emptyDist = map (fn (r,c) => ((r,c), sumDist (r,c) occupiedSeats)) emptySeats
      val orderedSeats = qsort isMore emptyDist
      val result = map (fn ((r,c),_) => coordToSeat (r,c)) orderedSeats
    in 
      result
    end

val pastSeats = [
    (3, 5, R),
    (1, 12, R),
    (4, 10, R),
    (4, 2, L),
    (3, 8, R),
    (1, 7, R),
    (3, 6, R),
    (4, 3, L),
    (2, 9, R),
    (1, 9, R),
    (2, 7, L),
    (4, 6, L),
    (1, 4, R),
    (1, 3, R),
    (3, 5, L)
]

