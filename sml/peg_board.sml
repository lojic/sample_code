(* Solve the Cracker Barrel Peg Board Puzzle *)

open List

(* Provide extra functionality *)
fun elem x xs = exists (fn e => e = x) xs
fun upto (m,n) = if m>n then [] else m :: upto(m+1,n)
val filter = filter
                     
type Pos   = int * int
type Move  = int * int
type Board = Pos list

fun isOccupied b p = elem p b
fun isEmpty b p    = not (isOccupied b p)
fun isPos (r,c)    = r >= 0 andalso r < 5 andalso c >= 0 andalso c <= r


(* Possible moves for one position *)
fun positionMoves b p =
    let val (r, c) = p
        val pairs  = filter 
                       (fn (neighbor,dst) => isPos neighbor        andalso 
                                             isPos dst             andalso 
                                             isOccupied b neighbor andalso 
                                             isEmpty b dst)
                       (map (fn (or,oc) => ((r + or div 2, c + oc div 2),(r + or, c + oc))) 
                            [ (~2,0), (0,2), (2,2), (2,0), (0,~2), (~2,~2) ])
    in map (fn (neighbor, dst) => (p, dst)) pairs end

(* Possible moves for all positions on the board *)
fun possibleMoves b = concat (map (fn pos => positionMoves b pos) b)

(* Make a move and return the new board *)
fun move b (src,dst) = 
    let val ((sr,sc),(dr,dc)) = (src,dst)
        val neighbor = ((sr+dr) div 2, (sc+dc) div 2)
    in dst :: filter (fn pos => (pos <> src) andalso (pos <> neighbor) ) b
    end
    
(* Make moves until the goal position is met *)
fun play b p moves =
    let val nextMoves = possibleMoves b
        fun tryMoves []      = []
          | tryMoves (m::ms) = 
            let val result = play (move b m) p (m::moves)
            in if null result then tryMoves ms
               else result
            end
    in if null nextMoves then 
         if length b = 1 andalso hd b = p then rev moves else []
       else tryMoves nextMoves
    end

(* Compute the initial empty position to know the goal, then solve the puzzle *)
fun solve b = 
    let fun emptyPos (r,c) = if isEmpty b (r,c) then (r,c)
                             else if c<r then emptyPos (r,c+1)
                             else emptyPos (r+1,0)
    in play b (emptyPos(0,0)) [] end
    
val board = [ (1,0), (1,1), 
              (2,0), (2,1), (2,2), 
              (3,0), (3,1), (3,2), (3,3), 
              (4,0), (4,1), (4,2), (4,3), (4,4) ] : Board


(*    
fun solve b = 
    let val emptyPos = 
            hd (filter (fn (r,c) => isEmpty b (r,c)) 
                            (foldr (fn (r,l) => foldr (fn (c,l) => (r,c)::l) l (upto(0,r))) [] (upto(0,4))))
    in play b emptyPos []
    end
*)    
