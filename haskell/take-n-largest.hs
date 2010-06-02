--take :: Num a => Int -> [b] -> [(a, b)]
--take n xs = map (\x -> (1,x)) xs


-- Provided in #haskell
import Data.List
import Data.Function

--let f n = map snd . sortBy (compare `on` fst) . take n . sortBy (flip compare `on` snd) . zip [1..] in f 4 $ [1,3..7]++[2,4..8]
f n = map snd . sortBy (compare `on` fst) . take n . sortBy (flip compare `on` snd) . zip [1..]

