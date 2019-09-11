(import 
   (owl base)
   (only (owl sys) peek-byte)
   (only (rad main) urandom-seed)
   (only (rad mutations) 
      mutators->mutator
      string->mutators default-mutations)
   (only (rad output) 
      stream-chunk)
   (only (rad patterns)
      default-patterns
      string->patterns)
   (only (rad generators)
      rand-block-size))

(import 
   (only (owl syscall) library-exit)) ;; library call return/resume

   

;; todo: add a proper read primop
(define (read-memory-simple ptr len)
   (if (eq? len 0)
      #null
      (cons (peek-byte ptr)
         (read-memory-simple (+ ptr 1) (- len 1)))))

(define (read-memory source len)
   (if (string? source)
      (take (string->bytes source) len)
      (read-memory-simple source len)))

;; rs ptr len → rs (bvec ...)
(define (read-memory->chunks rs source len)
   (if (> len 0)
      (lets 
         ((rs s (rand-block-size rs))
          (s (min s len))
          (rs tail (read-memory->chunks rs (+ source s) (- len s)))
          (bv (list->bytevector (read-memory-simple source s))))
         (values rs 
            (cons bv tail)))
      (values rs #null)))

(define mutas 
   (lets ((rs mutas 
            (mutators->mutator 
               (seed->rands 42)
               (string->mutators default-mutations))))
      mutas))

(define patterns 
   (string->patterns default-patterns))

;; fuzzer output is a ll of byte vectors followed by a #(rs muta meta) -tuple
;; generate a byte list (for now) of the data to be returned and also return 
;; the mutas, which is where radamsa learns

;; rs muta input-chunks → rs' muta' (byte ...)
(define (fuzz->output rs muta chunks)
   (print 42)
   (lets 
      ((routput (reverse (force-ll (patterns rs chunks muta #empty))))
       (state (car routput))
       (rs muta meta state)
       (output-bytes
          (fold
             (λ (out chunk)
                (let ((n (vector-length chunk)))
                   (if (eq? n 0)
                      out
                      (stream-chunk chunk (- n 1) out))))
             #null
             (cdr routput))))
       (values rs muta output-bytes)))
       

(define (mutate-simple mutator byte-list seed)
   (lets
      ((mutator rs chunks meta
         (mutator
            (seed->rands seed)
            (list (list->bytevector byte-list))
            #empty)))
      (values
         mutator
         (foldr
            (λ (bvec out)
               (append (bytevector->list bvec) out))
            '()
            chunks))))
            
(define (fuzz muta)
   (λ (tuple-from-c)
      ; (print "-> radamsa: " tuple-from-c)
      (lets 
         ((ptr len max seed tuple-from-c)
          (start (time-ms)))
         (if (= len 0)
            ((fuzz muta)
               (library-exit (list (band seed #xff))))
            (lets
               ((rs (seed->rands seed))
                ;(input (read-memory ptr len))
                (rs inputp (read-memory->chunks rs ptr len))
                ;(muta output (mutate-simple muta input seed))
                ;(output (cons 10 input))
                ;(output '(42 42 42))
                (rs muta output 
                   (fuzz->output rs muta inputp))
               )
               (print-to stderr
                  "Radamsa took " (- (time-ms) start) "ms")
               ((fuzz muta)
                  (library-exit output)))))))

(define (try entry)
   (let loop ((entry entry)
              (samples 
                 '("Hello <b>HAL</b> 9000" 
                   "Hello, world!" 
                   ))
              (n 1))
      (if (= n 100)
         12
         (lets 
            ((return entry
               (entry 
                  (tuple 
                     (car samples)
                     100
                     100
                     n))))
            (print n " -> " (list->string return))
            (loop entry (append (cdr samples) (list (car samples))) (+ n 1))))))

;; Entry test
;(define (wait arg)
;   (print "radamsa: i got something")
;   (wait (library-exit '(42 42 42))))
;wait

;; load-time test
; (try (fuzz mutas))

;; fasl test
; (λ (args) (try (fuzz mutas)))

;; C test
(fuzz mutas)


