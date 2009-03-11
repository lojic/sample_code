import Data.List
import Data.Ord
import Control.Monad

pets =
   [("dog", [("blab", 12),("glab", 17),("cbret", 82),
             ("dober", 42),("gshep", 25)]),
     ("cat", [("pers", 22),("siam", 7),("tibet", 52),
              ("russ", 92),("meow", 35)]),
     ("snake", [("garter", 10),("cobra", 37),("python", 77),
                ("adder", 24),("rattle", 40)]),
     ("cow", [("jersey", 200),("heiffer", 300),("moo", 400)])]

digest_tag tag_pop pick_tags count =
  let selected_pops = 
        [(i,(-c,b)) | (i,(a,bs)) <- zip [0..] tag_pop, a `elem` pick_tags,
                                    (b,c) <- bs]
      top_pops = sort $ take count (sortBy (comparing snd) selected_pops)
  in [(fst (tag_pop !! i), b, -c) | (i, (c,b)) <- top_pops]

main = print $ digest_tag pets ["dog","cat","snake"] 5

