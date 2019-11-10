
(defun foo (x)
  (plus x x))

(defun bar (x)
  (cond ((eq x 1) 1)
        (t 2)))

(defun tarai (x y z)
  (cond ((eqlessp x y) y)
        (t (tarai (tarai (sub1 x) y z)
                  (tarai (sub1 y) z x)
                  (tarai (sub1 z) x y)))))
