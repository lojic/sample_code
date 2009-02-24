; Based on unworking code by sacado on the Arc forum
; I fixed it and made the output match the challenge 
; e.g. [ 1, 5, 8, 6, 3, 7, 2, 4 ]
(def valid? (stack)
  (let q2 0
    (point return
           (each q1 (range 1 (- len.stack 1))
                 (if (or (is stack.q1 stack.q2)
                         (is (abs:- q1 q2) (abs:- stack.q1 stack.q2)))
                     (return nil)))
           t)))

(def joinstr (lst (o sep " "))
  (if lst
      (string (car lst) (apply string (map [string sep _] (cdr lst))))
      ""))

(def queens (stack n)
  (if (is n 8)
      (prn "[ " (joinstr (rev stack) ", ") " ]")
      (each rank (range 1 8)
            (push rank stack)
            (if (valid? stack)
                (queens stack (+ n 1)))
            (pop stack))))

(queens '() 0)