-- Scott Moonen emailed me about a "perfect shuffle"
-- The core idea is to shuffle a deck of cards by splitting in two and interleaving cards from both halves

-- My first Haskell attempt
shuffle1 xs = concat [[fst x, snd x] | x <- uncurry zip (splitAt (length xs `div` 2) xs)] 

-- My second attempt. Create a flatten_tup2 function: [(a,b),(c,d)] => [a,b,c,d]
shuffle2 xs = flatten_tup2 (uncurry zip (splitAt (length xs `div` 2) xs))
    where
      flatten_tup2 [] = []
      flatten_tup2 ((a,b):xs) = a : b : flatten_tup2 xs

-- #haskell help
-- Implement flatten_tup2 with foldr
shuffle3 xs = flatten_tup2 (uncurry zip (splitAt (length xs `div` 2) xs))
    where
      flatten_tup2 = foldr (\(a,b) c -> a:b:c) []

-- #haskell help
shuffle4 xs = do (x,y) <- uncurry zip (splitAt (length xs `div` 2) xs); [x,y]

-- #haskell help
shuffle5 xs = [z | (x,y) <- uncurry zip (splitAt (length xs `div` 2) xs), z <- [x,y]]

-- discovered parallel comprehensions. requires: ghci -XParallelListComp
-- using | instead of , causes the generators to operate in parallel
shuffle6 xs = concat [[x,y] | x <- left | y <- right]
    where 
      (left, right) = splitAt (length xs `div` 2) xs
                      
-- comp.lang.haskel, Dirk Thierbach 
-- compare to shuffle1 - remove fst, snd by pattern matching
shuffle7 xs = concat [[x,y] | (x,y) <- uncurry zip (splitAt (length xs `div` 2) xs)] 

-- comp.lang.haskel, Dirk Thierbach 
-- interleave operator "AFAIK by Mark Jones"
(/\/) :: [a] -> [a] -> [a]
[]     /\/ ys = ys
(x:xs) /\/ ys = x : (ys /\/ xs)
shuffle8 xs = uncurry (/\/) $ splitAt (length xs `div` 2) $ xs

-- comp.lang.haskell Lauri Alanko
-- using parallel list comprehensions (same as mine above)
shuffle9 xs = concat [[a, b] | a <- l1 | b <- l2] 
    where (l1, l2) = splitAt (length xs `div` 2) xs

-- comp.lang.haskell Lauri Alanko
-- w/o list comprehensions
shuffle10 xs = concat (zipWith (\a b -> [a, b]) l1 l2)
    where (l1, l2) = splitAt (length xs `div` 2) xs

-- comp.lang.haskel, Dirk Thierbach 
-- different algorithm, but interesting
everySnd []  = []
everySnd [x] = [x]
everySnd (x:_:xs) = x : everySnd xs
shuffle9 xs = everySnd xs ++ everySnd (tail xs)

-- suggested on #haskell, but different algorithm, still interesting :)
-- uncurry (++) . foldr (\e (l,r) -> (e:r,l)) ([],[]) $ [1..20]

