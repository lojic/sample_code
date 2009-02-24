;; My original print-choice
;;(defun print-choice (lst)
;;  (dolist (i lst) (format t "~a " i))
;;  (format t "~%"))
;;
;;  (print-choice sofar)
;;  replaced by format statement below

(defun choices (menu &optional (sofar '()))
  (if menu 
    (dolist (i (car menu)) 
      (choices (cdr menu) (append sofar (list i))))
    (format t "~{~a~^ ~}~%" sofar)))

(choices (list
           (list "small" "medium" "large")
           (list "vanilla" "ultra chocolate" "lychee" "rum raisin" "ginger")
           (list "cone" "cup")))
