(* This program will produce an ordered set of potential seats given a
   list of previously occupied seats and an auditorium layout. Seats
   are ordered so as to be "furthest" from all previously occupied
   seats.

   For example, given the auditorium layout below showing the virtual
   border seats as X and reserved actual seats as R and the two
   previous seat choices of 2-2-R and 4-5-L as *, the program would
   choose the best candidate seat as 2-9-R shown as S.


   |    |   | S1 | S1 | S2 | S2 | S3 | S3 | S4 | S4 |   |
   |    | 0 | 1  | 2  | 3  | 4  | 5  | 6  | 7  | 8  | 9 |
   |----+---+----+----+----+----+----+----+----+----+---|
   |  0 | X | X  | X  | X  | X  | X  | X  | X  | X  | X |
   |  1 | X | R  | R  |    |    |    |    |    |    | X |
   |  2 | X |    |    |    | *  |    |    |    |    | X |
   |  3 | X |    |    |    |    |    |    |    |    | X |
   |  4 | X |    |    |    |    |    |    |    |    | X |
   |  5 | X |    |    |    |    |    |    | *  |    | X |
   |  6 | X |    |    |    |    |    |    |    |    | X |
   |  7 | X |    |    |    |    |    |    |    |    | X |
   |  8 | X |    |    |    |    |    |    |    |    | X |
   |  9 | X |    |    |    | S  |    |    |    |    | X |
   | 10 | X |    |    |    |    |    |    |    |    | X |
   | 11 | X |    |    |    |    |    |    |    |    | X |
   | 12 | X |    |    | R  | R  |    |    |    |    | X |
   | 13 | X | R  | R  | R  | R  |    |    | R  | R  | X |
   | 14 | X | X  | X  | X  | X  | X  | X  | X  | X  | X |
   |----+---+----+----+----+----+----+----+----+----+---|   *)

open List

(* Position within a single row - left or right *)
datatype position = L | R

val gravity      = 1.0
val low_gravity  = 0.070078125 (* Empirically determined to give "good" results *)
val numCols      = 8
val numPositions = 2
val numRows      = 13

type Row     = int
type Section = int
type Seat    = Section * Row * position
type Coord   = int * int
               
(************************************************************
 * General Support Functions
 ************************************************************)

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

(* Indicate whether an element is in a list *)
fun elem x xs = exists (fn e => e = x) xs

fun isLess ((_,_), (a:real)) ((_,_), (b:real)) = a < b
fun isMore ((_,_), (a:real)) ((_,_), (b:real)) = a > b
fun max a b = if a > b then a else b
fun min a b = if a < b then a else b
                                   
fun qsort f [] = []
  | qsort f (x::xs) =
    let val (larger, smaller) = List.partition (f x) xs
    in qsort f smaller @ [x] @ qsort f larger end
                                  
(* upto(3,7) -> [3, 4, 5, 6, 7] *)                                   
fun upto (m,n) = if m>n then [] else m :: upto(m+1,n)

(************************************************************
 * Seating Utility Functions
 ************************************************************)
                                     
fun indexFromPosition L = 0
  | indexFromPosition R = 1

fun positionFromIndex 0 = L
  | positionFromIndex 1 = R

fun seatToCoord ((s,r,p):Seat) = (r, (s-1)*numPositions + indexFromPosition(p) + 1)

fun coordToSeat (row,col) =
    ((col-1) div numPositions + 1, row, positionFromIndex ((col-1) mod numPositions))
    
fun coordDistanceSquared (r1, c1) (r2, c2) =
    let val (x1,y1,x2,y2) = (real(r1),real(c1),real(r2),real(c2))
    in Math.pow(x1-x2,2.0) + Math.pow(y1-y2,2.0) end

fun sumDist (r,c) [] = 0.0
  | sumDist (r,c) ((r',c',g)::xs) = (g / (coordDistanceSquared (r,c) (r',c'))) + sumDist (r,c) xs

(* List of seats unavailable for sitting in - including virtual bordering seats 
   for allowing modeling of peripheral "gravity" *)
fun reservedSeats() =
    let 
      val lastSeat        = (1,4) (* Reserve until only remaining seat *)
      val micVettingSeats = [ (1,1),(1,2) ]
      val section1Missing = [ (13,1),(13,2) ] (* Section 1 has 12 rows *)
      val section2Missing = [ (12,3),(12,4),(13,3),(13,4) ] (* Section 2 has 11 rows *)
      val section4Missing = [ (13,7),(13,8) ] (* Section 4 has 12 rows *)
      val topBorder       = (map (fn i => (0,i)) (upto(0,9)))
      val rightBorder     = (map (fn i => (14,i)) (upto(0,9)))
      val bottomBorder    = (map (fn i => (i,9)) (upto(1,13)))
      val leftBorder      = (map (fn i => (i,0)) (upto(1,13)))
    in 
      [ lastSeat ] @ micVettingSeats @ section1Missing @ section2Missing @ section4Missing @
      topBorder @ rightBorder @ bottomBorder @ leftBorder
    end

val pastSeats = [
    (1, 3, R),  (* 08/07/11 *)
    (1, 4, R),  (* 08/14/11 *)
    (1, 6, L),  (* 11/27/11 *)
    (1, 7, R),  (* 10/02/11 *)
    (1, 9, R),  (* 09/04/11 *)
    (1, 12, R), (* 11/06/11 *)
    (2, 7, L),  (* 08/28/11 *)
    (2, 9, R),  (* 09/11/11 *)
    (3, 5, L),  (* 07/31/11 *)
    (3, 5, R),  (* 11/20/11 *)
    (3, 6, R),  (* 09/25/11 *)
    (3, 8, R),  (* 10/09/11 *)
    (3, 13, R), (* 12/04/11 *)
    (4, 2, L),  (* 10/16/11 *)
    (4, 3, L),  (* 09/18/11 *)
    (4, 6, L),  (* 08/21/11 *)
    (4, 10, R)  (* 10/23/11 *)
]

(* Primary Function:
 
   1) Convert seating history from [ (section,row,position), ... ] to
      [ (row,column), ... ] and assign to occupiedSeats
   2) Create a list of all possible seats and assign to allSeats
   3) Filter out reserved and occupiedSeats from allSeats and assign to emptySeats
   4) Create a list of non-empty seats with an associated "gravity" of "normal" for 
      occupiedSeats and "low" for reservedSeats and assign to gravitySeats. The "low" 
      gravity for reservedSeats is to prevent the algorithm from biasing the peripheral 
      seats too heavily
   5) For each empty seat, compute an evaluation by summing the product of gravity and
      the square of the distance between the empty seat and every seat in gravitySeats and
      assign to evaluated
   6) Sort the evaluated list and assign to orderedSeats
   7) Lastly, map the (row,col) coords back to (section,row,position) values

*)
      
fun candidates pastSeats =
    let 
      val occupiedSeats = map seatToCoord pastSeats
      val allSeats      = map (fn e => (hd e, hd (tl e))) 
                              (cartesian [ upto(1,numRows), upto(1,numCols) ])
      val emptySeats    = filter 
                            (fn e => not (elem e occupiedSeats orelse elem e (reservedSeats())))
                            allSeats
      val gravitySeats  = (map (fn (r,c) => (r,c,gravity)) occupiedSeats) @ 
                          (map (fn (r,c) => (r,c,low_gravity)) (reservedSeats()))
      val evaluated     = map (fn (r,c) => ((r,c), sumDist (r,c) gravitySeats)) emptySeats
      val orderedSeats  = qsort isLess evaluated
      fun format((r,c),g) = 
          let 
            val (s,r,p) = coordToSeat (r,c)
          in 
            (s,r,p,g)
          end
    in 
      map format orderedSeats
    end

val result = candidates pastSeats
