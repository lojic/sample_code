(define (move n from to spare)
  (cond ((= n 0) "done")
        (else
          (move (- n 1) from spare to)
          (print-move from to)
          (move (- n 1) spare to from))))

