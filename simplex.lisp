(set 'R 8.31)

(define (b11 x0 x2 T0 T1 T2)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 x0)
       (z2 (sub 1 x0))
       (g (add (mul z1 (log z1))
	       (mul z2 (log z2)))))
    (div (sub T0 T1)
	 (mul R T0 T1 g))))

(define (b12 x0 x2 T0 T1 T2)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 (div x1 (sub 1 x0)))
       (z2 (div x2 (sub 1 x0)))
       (g (add (mul z1 (log z1))
	       (mul z2 (log z2)))))
    (div (sub T1 T2)
	 (mul R T1 T2 g))))

(define (b21 x0 x2 T0 T1 T2)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 (add x0 x1))
       (z2 x2)
       (g (add (mul z1 (log z1))
	       (mul z2 (log z2)))))
    (div (sub T1 T2)
	 (mul R T1 T2 g))))

(define (b22 x0 x2 T0 T1 T2)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 (div x0 (sub 1 x2)))
       (z2 (div x1 (sub 1 x2)))
       (g (add (mul z1 (log z1))
	       (mul z2 (log z2)))))
    (div (sub T0 T1)
	 (mul R T0 T1 g))))

(define (a11 x0 x2 T0 T1 T2 bB bD k r)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 x0)
       (z2 (sub 1 x0))
       (g (mul R (add (mul z1 (log z1))
		      (mul z2 (log z2)))))
       (e (add (div 1 (mul bB (mul T1 T1)))
	       (div 1 (mul bD (mul T0 T0)))
	       (div 2 (mul k (mul r r))))))
    (sub (mul (div 1 g) e))))

(define (a12 x0 x2 T0 T1 T2 bB bD k r)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 (div x1 (sub 1 x0)))
       (z2 (div x2 (sub 1 x0)))
       (g (mul R (add (mul z1 (log z1))
		      (mul z2 (log z2)))))
       (e (add (div 1 (mul bB (mul T2 T2)))
	       (div 1 (mul bD (mul T1 T1)))
	       (div 2 (mul k (mul r r))))))
    (sub (mul (div 1 g) e))))

(define (a21 x0 x2 T0 T1 T2 bB bD k r)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 (add x0 x1))
       (z2 x2)
       (g (mul R (add (mul z1 (log z1))
		      (mul z2 (log z2)))))
       (e (add (div 1 (mul bB (mul T2 T2)))
	       (div 1 (mul bD (mul T1 T1)))
	       (div 2 (mul k (mul r r))))))
    (sub (mul (div 1 g) e))))

(define (a22 x0 x2 T0 T1 T2 bB bD k r)
  (letn
      ((x1 (sub 1 x0 x2))
       (z1 (div x0 (sub 1 x2)))
       (z2 (div x1 (sub 1 x2)))
       (g (mul R (add (mul z1 (log z1))
		      (mul z2 (log z2)))))
       (e (add (div 1 (mul bB (mul T1 T1)))
	       (div 1 (mul bD (mul T0 T0)))
	       (div 2 (mul k (mul r r))))))
    (sub (mul (div 1 g) e))))

(define (q1 x0 x2 T0 T1 T2 bB1 bD1 bB2 bD2 k11 k12 r0 r1 gF)
  (letn
      ((g11 (b11 x0 x2 T0 T1 T2))
       (e11 (a11 x0 x2 T0 T1 T2 bB1 bD1 k11 r0))
       (g12 (b12 x0 x2 T0 T1 T2))
       (e12 (a11 x0 x2 T0 T1 T2 bB2 bD2 k12 r1))
       (q11 (div (sub g11
		      (sqrt (sub (mul g11 g11)
				 (mul 4 e11 gF))))
		 (mul 2 e11)))
       (q12 (div (sub g12
		      (sqrt (sub (mul g12 g12)
				 (mul 4 e12 gF (sub 1 x0)))))
		 (mul 2 e12))))
;    (println "maxg1: " (div (mul g11 g11)
;			    (mul 4 e11)))
    (add q11 q12)))

(define (q2 x0 x2 T0 T1 T2 bB1 bD1 bB2 bD2 k21 k22 r0 r1 gF)
  (letn
      ((x1 (sub 1 x0 x2))
       (r01 (div (add (mul r0 x0)
		      (mul r1 x1))
		 (add x0 x1)))
       (g21 (b21 x0 x2 T0 T1 T2))
       (e21 (a21 x0 x2 T0 T1 T2 bB1 bD1 k21 r01))
       (g22 (b22 x0 x2 T0 T1 T2))
       (e22 (a21 x0 x2 T0 T1 T2 bB2 bD2 k22 r0))
       (q21 (div (sub g21
		      (sqrt (sub (mul g21 g21)
				 (mul 4 e21 gF))))
		 (mul 2 e21)))
       (q22 (div (sub g22
		      (sqrt (sub (mul g22 g22)
				 (mul 4 e22 gF (sub 1 x2)))))
		 (mul 2 e22))))
;    (println "maxg2: " (div (mul g21 g21)
;			    (mul 4 e21)))
    (add q21 q22)))

(define (b1 x0 x2 T0 T1 T2)
  (let
      ((g11 (b11 x0 x2 T0 T1 T2))
       (g12 (b12 x0 x2 T0 T1 T2)))
    (div (mul g11 g12)
	 (add g12 (mul g11 (sub 1 x0))))))

(define (b2 x0 x2 T0 T1 T2)
  (let
      ((g21 (b21 x0 x2 T0 T1 T2))
       (g22 (b22 x0 x2 T0 T1 T2)))
    (div (mul g21 g22)
	 (add g22 (mul g21 (sub 1 x2))))))

(define (prevail x0 x2 T0 T1 T2)
  (sub (b1 x0 x2 T0 T1 T2)
       (b2 x0 x2 T0 T1 T2)))

(define (prevail2 x0 x2 T0 T1 T2 bB11 bD11 bB12 bD12 bB21 bD21 bB22 bD22 k11 k12 k21 k22 r0 r1 gF)
  (let ((q1 (q1 x0 x2 T0 T1 T2 bB11 bD11 bB12 bD12 k11 k12 r0 r1 gF))
	(q2 (q2 x0 x2 T0 T1 T2 bB21 bD21 bB22 bD22 k21 k22 r0 r1 gF)))
    (sub q1 q2)))

(define (cprev2 x0 x2)
  (prevail2 x0 x2 393 438 458
	    25000 50000 10000 45000
	    25000 50000 10000 45000
	    13 11 15 13 50000 70000 1))

(define (bisect f a b eps)
  (while (> (div (sub b a) 2) eps)
    (let ((c (div (add b a) 2)))
      (if (> (mul (f c) (f a)) 0)
	  (set 'a c)
	(set 'b c)))))


(set 'T0 393 'T1 438 'T2 458)

; inequality (3.19)
(define (s x0 x2 T0 T1 T2)
  (letn
      ((x1 (sub 1 x0 x2))
       (m1 (mul T2 (sub T1 T0)))
       (m2 (mul T0 (sub T2 T1)))
       (g1 (add (mul x1 (log (div x1 (sub 1 x0))))
		(mul x2 (log (div (sub 1 x2) (sub 1 x0))))
		(sub (log (sub 1 x2)))))
       (g2 (add (mul x1 (log (div x1 (sub 1 x2))))
		(mul x0 (log (div (sub 1 x0) (sub 1 x2))))
		(sub (log (sub 1 x0))))))
    (sub (mul m1 g1)
	 (mul m2 g2))))
       

(for (x2 0.01 0.49 0.01)
  (letn ((f (lambda (x2) (prevail 0.5 x2 T0 T1 T2)))
	 (x3 (bisect f 0.001 1 1e-12))
	 (x0 0.5)
	 )
    (println "x2: " x2)
    (println (prevail x0 x2 T0 T1 T2) " : " (s x0 x2 T0 T1 T2))
    (println "b12: " (b12 x0 x2 T0 T1 T2) " b22: " (b22 x0 x2 T0 T1 T2))
    (println "b1: " (b1 x0 x2 T0 T1 T2) " b2: " (b2 x0 x2 T0 T1 T2))
    ;(println x0 " : " x2)
    ))

(println)
(println "################################")
(println)

;(for (x0 0.01 0.99 0.01)
;  (letn ((f (lambda (x2) (cprev2 x0 x2)))
;	 (x2 (bisect f 0.01 1 1e-14))
;	 (q1 (q1 x0 x2 393 438 458 25000 50000 10000 45000 13 11 50000 70000 10))
;	 (q2 (q2 x0 x2 393 438 458 25000 50000 10000 45000 15 13 50000 70000 0.01)))
;    (println "q1: " q1 " q2: " q2 " x0: " x0 " x2: " x2)))
;    (println x0 " : " x2)))

;(println (b21 0.5 0.2 393 438 458))
;(exit)
