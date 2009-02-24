  (def foldl (op initial sequence)
    (def iter (result rest)
      (if (no rest)
        result
        (iter (op result (car rest))
              (cdr rest))))
    (iter initial sequence))

  (def foldl (op initial sequence)
    (let iter (afn (result rest)
                (if (no rest)
                  result
                  (self (op result (car rest))
                        (cdr rest))))
      (iter initial sequence)))

  (def foldl (op initial sequence)
    (let iter (afn (result rest)
                (if (no rest)
                  result
                  (self (op result (car rest))
                        (cdr rest))))
      (iter initial sequence)))

