{-
(>>=)  :: Parser a -> (a -> Parser b) -> Parser b
p >>= f = \inp -> case parse p inp of
                    [] -> []
                    [(v,out)] -> parse (f v) out

failure :: Parser a
failure = \inp -> []

-}

import Parsing

p :: Parser (Char, Char)
p = do x <- item
       item
       y <- item
       return (x,y)

main = print (parse p "abcdef")