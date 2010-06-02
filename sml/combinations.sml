fun combinations (0, _) = [[]]
  | combinations (_, []) = []
  | combinations (m, h::t) = map (fn y => h :: y) (combinations (m-1, t)) @ combinations (m, t)
