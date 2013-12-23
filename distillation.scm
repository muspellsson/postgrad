;; Universal gas constant
(define +R+ 8.31)

;; Binary mixture
;; x0 - concentration of the lower boiling component
;; x1 - concentration of the higher boiling component
;; T0 - evaporation temperature of the LBC
;; T1 - evaporation temperature of the HBC
;; r0 - molar evaporating heat of the LBC
;; Molar evaporating heat of the HBC is not really needed
(define-structure mixture2 x0 x1 T0 T1 r0)

;; Ternary mixture
;; x0 - concentration of the LBC
;; x1 - concentration of the M(Middle)BC
;; x2 - concentration of the HBC
;; T0-T2 - corresponding evaporating temperatures
;; r0-r2 - corresponding molar evaporating heats
;; Again, molar evaporating heat of the HBC
;; is not really needed
(define-structure mixture3 x0 x1 x2 T0 T1 T2 r0 r1)

;; Fractionating column
;; bB - heat-transfer coefficient of the reboiler
;; bD - heat-transfer coefficient of the reflux drum
;; k  - mass-transfer coefficient throughout the column
(define-structure column bB bD k)

;; Energy needed to separate some mixture
;; Binary mixtures can be separated in the only one way
;; Ternary mixtures can be separated in the direct order,
;; when the LBC is separated first, or in the indirect order,
;; when the HBC is separated first
;; point = 0 for direct order
;; point = 1 for indirect order
(define (separation-energy mixture #!optional point)
  (let ((gibbs-energy
	 ;; x - concentration of the lower boiling
	 ;; quasi-component
	 ;; TD - temperature in the reflux drum,
	 ;; equal to the evaporation temperature of
	 ;; LB(q)C
	 (lambda (TD x)
	   (- (* +R+ TD
		 (+ (* x (log x))
		    (* (- 1 x) (log (- 1 x)))))))))
    (cond
     ;; Binary mixture case
     ((mixture2? mixture)
      (if point
	  (error "Binary mixtures can be separated in only one way")
	  ;; For binary mixture quasi-components are real components
	  (let* ((x0 (mixture2-x0 mixture))
		 (TD (mixture2-T0 mixture)))
	    (gibbs-energy TD x0))))
     ((mixture3? mixture)
      (if point
	  ;; For ternary mixture we must consider some
	  ;; quasi-components
	  ;; For the indirect order the lower boiling
	  ;; quasi-component is the mixture of LBC and MBC
	  (let* ((x0 (case point
		       ((0) (mixture3-x0 mixture))
		       ((1) (+ (mixture3-x0 mixture)
			       (mixture3-x1 mixture)))
		       (else
			(error "Wrong separation point"))))
		 (TD (case point
		       ((0) (mixture3-T0 mixture))
		       ((1) (mixture3-T1 mixture))
		       (else
			(error "Wrong separation point")))))
	    (gibbs-energy TD x0))
	  (error "Separation of ternary mixture is ambigious"))))))

;; Efficiency coefficient for separation
;; of given mixture without considering
;; and irreversibility
(define (reversible-efficiency mixture #!optional point)
  (let ((efficiency
	 ;; TB - temperature in the reboiler,
	 ;; equal to the evaporation temperature of HBC
	 ;; TD - temperature in the reflux drum
	 (lambda (TB TD mixture #!optional point)
	   (/ (- TB TD)
	      (* TB (separation-energy mixture point))))))
    (cond
     ((mixture2? mixture)
      (if point
	  (error "Binary mixtures can be separated in only one way")
	  (let ((TD (mixture2-T0 mixture))
		(TB (mixture2-T1 mixture)))
	    (efficiency TB TD mixture))))
     ((mixture3? mixture)
      (if point
	  (let ((TD (case point
		      ((0) (mixture3-T0 mixture))
		      ((1) (mixture3-T1 mixture))
		      (else
		       (error "Wrong separation point"))))
		(TB (case point
		      ((0) (mixture3-T1 mixture))
		      ((1) (mixture3-T2 mixture))
		      (else
		       (error "Wrong separation point")))))
	    (efficiency TB TD mixture point))
	    (error "Separation of ternary mixture is ambigious"))))))

;; Entropy ``production'' from heat- and
;; mass-transfer irreversibility
;; Deals not only with mixture, but with column too
(define (entropy column mixture #!optional point)
  (let ((sigma
	 ;; TB - temperature in the reboiler
	 ;; TD - temperature in the reflux drum
	 ;; column - column model
	 ;; r - molar evaporating heat of LB(q)C
	 (lambda (column TB TD r)
	   (let ((bB (column-bB column))
		 (bD (column-bD column))
		 (k  (column-k column)))
	     (exact->inexact
	      (+ (/ 1 (* bB (expt TB 2)))
		 (/ 1 (* bD (expt TD 2)))
		 (/ 2 (* k (expt r 2)))))))))
    (cond
     ((mixture2? mixture)
      (if point
	  (error "Binary mixtures can be separated in only one way")
	  (let ((TD (mixture2-T0 mixture))
		(TB (mixture2-T1 mixture))
		(r (mixture2-r0 mixture)))
	    (sigma column TB TD r))))
     ((mixture3? mixture)
      (if point
	  (let ((TD (case point
		      ((0) (mixture3-T0 mixture))
		      ((1) (mixture3-T1 mixture))
		      (else
		       (error "Wrong separation point"))))
		(TB (case point
		      ((0) (mixture3-T1 mixture))
		      ((1) (mixture3-T2 mixture))
		      (else
		       (error "Wrong separation point"))))
		(r (case point
		     ((0) (mixture3-r0 mixture))
		     ((1)
		      (let ((r0 (mixture3-r0 mixture))
			    (r1 (mixture3-r1 mixture))
			    (x0 (mixture3-x0 mixture))
			    (x1 (mixture3-x1 mixture)))
			(/ (+ (* r0 x0) (* r1 x1)) (+ x0 x1))))
		     (else
		      (error "Wrong separation point")))))
	    (sigma column TB TD r))
	  (error "Separation of ternary mixture is ambigious"))))))

;; Coefficient determining the loss of
;; column productivity due to irreversibility of
;; internal processes
(define (irreversibility column mixture #!optional point)
  (let ((coefficient
	 ;; arguments here are straightforward
	 (lambda (column mixture TD #!optional point)
	   (/ (* (entropy column mixture point) TD)
	      (separation-energy mixture point)))))
    (cond
     ((mixture2? mixture) 
      (if point
	  (error "Binary mixtures can be separated in only one way")
	  (let ((TD (mixture2-T0 mixture)))
	    (coefficient column mixture TD))))
     ((mixture3? mixture)
      (if point
	  (let ((TD (case point
		      ((0) (mixture3-T0 mixture))
		      ((1) (mixture3-T1 mixture))
		      (else
		       (error "Wrong separation point")))))
	    (coefficient column mixture TD point))
	  (error "Separation of ternary mixture is ambigious"))))))

;; Function for producing a corrected 
;; binary submixture from a ternary mixture
(define (separate-mixture mixture3 point)
  (if (mixture3? mixture3)
      (case point
	((0)
	 (let ((T0 (mixture3-T1 mixture3))
	       (T1 (mixture3-T2 mixture3))
	       (x0 (/ (mixture3-x1 mixture3)
		      (- 1 (mixture3-x0 mixture3))))
	       (x1 (/ (mixture3-x2 mixture3)
		      (- 1 (mixture3-x0 mixture3))))
	       (r0 (mixture3-r1 mixture3)))
	   (make-mixture2 x0 x1 T0 T1 r0)))
	((1)
	 (let ((T0 (mixture3-T0 mixture3))
	       (T1 (mixture3-T1 mixture3))
	       (x0 (/ (mixture3-x0 mixture3)
		      (- 1 (mixture3-x2 mixture3))))
	       (x1 (/ (mixture3-x1 mixture3)
		      (- 1 (mixture3-x2 mixture3))))
	       (r0 (mixture3-r0 mixture3)))
	   (make-mixture2 x0 x1 T0 T1 r0)))
	(else
	 (error "Wrong separation point")))
      (error "This function is used to get binary mixture from ternary")))

;; Maximal productivity of the cascade,
;; distillating the ternary mixture
;; TODO: procedures for individual columns
(define (maximal-productivity col1 col2 mixture point)
  (let* ((x (case point
	      ((0) (mixture3-x0 mixture))
	      ((1) (mixture3-x2 mixture))
	      (else
	       (error "Wrong separation point"))))
	 (m (separate-mixture mixture point))
	 (b1 (reversible-efficiency mixture point))
	 (b2 (reversible-efficiency m))
	 (a1 (irreversibility col1 mixture point))
	 (a2 (irreversibility col2 m))
	 (gF1 (/ (expt b1 2) (* 4 a1)))
	 (gF2 (/ (/ (expt b2 2) (* 4 a2)) (- 1 x))))
    (min gF1 gF2)))

;; Heat required by the column cascade to
;; reach certain productivity
;; TODO: unreachability
(define (required-heat col1 col2 mixture productivity point)
  (let* ((x (case point
	      ((0) (mixture3-x0 mixture))
	      ((1) (mixture3-x2 mixture))
	      (else
	       (error "Wrong separation point"))))
	 (m  (separate-mixture mixture point))
	 (b1 (reversible-efficiency mixture point))
	 (b2 (reversible-efficiency m))
	 (a1 (irreversibility col1 mixture point))
	 (a2 (irreversibility col2 m))
	 (q1 (/ (- b1 (sqrt (- (expt b1 2)
			       (* 4 a1 productivity))))
		(* 2 a1)))
	 (q2 (/ (- b2 (sqrt (- (expt b2 2)
			       (* 4 a2 productivity (- 1 x)))))
		(* 2 a2)))
	 )
    (+ q1 q2)
    )
)

(define gF 0.2)
(define m  (make-mixture3 0.5 0.3 0.2 393 438 458 50000 70000))
(define m1 (separate-mixture m 0))
(define m2 (separate-mixture m 1))
(define c11 (make-column 20000 22000 13))
(define c12 (make-column 70000 75000 11))
(define c21 (make-column 20000 22000 15))
(define c22 (make-column 70000 75000 13))

(define b11 (reversible-efficiency m 0))
(define b12 (reversible-efficiency m1))
(define b21 (reversible-efficiency m 1))
(define b22 (reversible-efficiency m2))
(pp "*******")
(define a11 (irreversibility c11 m 0))
(define a12 (irreversibility c12 m1))
(define a21 (irreversibility c21 m 1))
(define a22 (irreversibility c22 m2))

(pp a11)
(pp a12)
(pp a21)
(pp a22)

(pp (/ (expt b12 2) (* 0.5 a12)))
(pp (/ (expt b11 2) a11))
(newline)
(pp (/ (expt b22 2) (* 0.8 a22)))
(pp (/ (expt b21 2) a21))
(pp "*******")
(pp (maximal-productivity c11 c12 m 0))
(pp (maximal-productivity c21 c22 m 1))
(pp "*******")
(pp (required-heat c11 c12 m 1 0))
(pp (required-heat c21 c22 m 1 1))

;; (define (max-gF m)
;;   (min (maximal-productivity c11 c12 m 0)
;;        (maximal-productivity c21 c22 m 1)))

;; (define (heat-delta m)
;;   (- (required-heat c11 c12 m gF 0)
;;      (required-heat c21 c22 m gF 1)))

;; (pp "********")
;; (pp (max-gF m))
;; (pp (heat-delta m))

;; (define (generate-mixtures x0 T0 T1 T2 r0 r1 r2 step)
;;   (let loop ((x2 step) (mixes '()))
;;     (if (> (+ x0 x2 step) 1)
;; 	(reverse mixes)
;; 	(loop (+ x2 step)
;; 	      (cons (make-mixture3 x0 (- 1 x0 x2) x2 T0 T1 T2 r0 r1 r2)
;; 		    mixes)))))

;; (define (find-zeroes lst eps)
;;   (let loop ((zeroes '()) (acc lst) (i 0))
;;     (if (null? (cdr acc))
;; 	(reverse zeroes)
;; 	(if (< (* (car acc) (cadr acc)) 0)
;; 	    (loop (cons (* i eps) zeroes)
;; 		  (cdr acc)
;; 		  (+ i 1))
;; 	    (loop zeroes
;; 		  (cdr acc)
;; 		  (+ i 1))))))

;; (define +eps+ 0.005)
;; (define mixes (generate-mixtures 0.265 393 438 458 50000 70000 0 +eps+))
;; (define (calculate)
;;   (let loop ((x0 +eps+) (c1 '()) (c2 '()))
;;     (let ((zeroes
;; 	   (find-zeroes
;; 	    (map heat-delta
;; 		 (generate-mixtures x0 393 438 458 50000 70000 0 +eps+))
;; 	    +eps+)))
;;       (if (null? zeroes)
;; 	  (cons (reverse c1) (reverse c2))
;; 	  (let ((z0 (car zeroes))
;; 		(z1 (if (null? (cdr zeroes)) (car zeroes) (cadr zeroes))))
;; 	    (loop (+ x0 +eps+)
;; 		  (cons (cons x0 z0) c1)
;; 		  (cons (cons x0 z1) c2)))))))

;; (define vals (calculate))
;; (with-output-to-file "1"
;;   (lambda ()
;;     (for-each
;;      (lambda (pair)
;;        (display (car pair))
;;        (display " ")
;;        (display (cdr pair))
;;        (newline))
;;      (car vals))))
;; (with-output-to-file "2"
;;   (lambda ()
;;     (for-each
;;      (lambda (pair)
;;        (display (car pair))
;;        (display " ")
;;        (display (cdr pair))
;;        (newline))
;;      (cdr vals))))
  
