package require Tk 8.6

source distillation-0.1.tm

# Gas constant
set R   8.3144621
# Epsilon
set eps 1e-15

# Canvas and it's frame
set    w 440
set    h 440
frame  .plot
canvas .plot.canvas -bg white -width $w -height $h
pack   .plot.canvas
pack   .plot -side left

# ==== Mixture ====

# Mixture parameters
set mIdcs [list 0 1 2]

# Concentrations
frame .xs
label .xs.label -text "Concentrations"
pack  .xs.label
foreach idx $mIdcs {
    set   x$idx 0
    frame .xs.x$idx
    label .xs.x$idx.label -text x$idx
    pack  .xs.x$idx.label
    entry .xs.x$idx.entry -textvar x$idx -width 18 \
	-validate key -vcmd {string is double %P}
    pack  .xs.x$idx.entry
    pack  .xs.x$idx -side left
}
pack .xs

# Boiling temperatures
frame .ts
label .ts.label -text "Boiling temperatures"
pack  .ts.label
foreach idx $mIdcs {
    set   T$idx 0
    frame .ts.t$idx
    label .ts.t$idx.label -text T$idx
    pack  .ts.t$idx.label
    entry .ts.t$idx.entry -textvar T$idx -width 18 \
	-validate key -vcmd {string is double %P}
    pack  .ts.t$idx.entry
    pack  .ts.t$idx -side left
}
pack .ts

# Molar boiling heats
set   bhIdcs [list 0 1]
frame .bhs
label .bhs.label -text "Molar boiling heats"
pack  .bhs.label
foreach idx $bhIdcs {
    set   r$idx 0
    frame .bhs.r$idx -padx 20
    label .bhs.r$idx.label -text r$idx
    pack  .bhs.r$idx.label
    entry .bhs.r$idx.entry -textvar r$idx \
	-validate key -vcmd {string is double %P}
    pack  .bhs.r$idx.entry
    pack  .bhs.r$idx -side left
}
pack .bhs

# ==== Columns ====

# Heat transfer coefficients
set   htIdcs [list B1 D1 B2 D2]
frame .htcs
label .htcs.label -text "Heat transfer coefficients"
pack  .htcs.label
foreach idx $htIdcs {
    set   B$idx 0
    frame .htcs.b$idx -padx 2
    label .htcs.b$idx.label -text B$idx
    pack  .htcs.b$idx.label
    entry .htcs.b$idx.entry -textvar B$idx -width 13 \
	-validate key -vcmd {string is double %P}
    pack  .htcs.b$idx.entry
    pack  .htcs.b$idx -side left
}
pack .htcs

# Mass transfer coefficients
set   mtIdcs [list 11 12 21 22]
frame .mtcs
label .mtcs.label -text "Mass transfer coefficients"
pack  .mtcs.label
foreach idx $mtIdcs {
    set   k$idx 0
    frame .mtcs.k$idx -padx 2
    label .mtcs.k$idx.label -text k$idx
    pack  .mtcs.k$idx.label
    entry .mtcs.k$idx.entry -textvar k$idx -width 13 \
	-validate key -vcmd {string is double %P}
    pack  .mtcs.k$idx.entry
    pack  .mtcs.k$idx -side left
}
pack .mtcs

set         swap1 0
set         swap2 0
frame       .swap
checkbutton .swap.b1 -text "Swap columns for direct order" -variable swap1
checkbutton .swap.b2 -text "Swap columns for indirect order" -variable swap2
pack        .swap.b1 -side left
pack        .swap.b2
pack        .swap

frame  .button
button .button.b -text "Plot attainability area" -command calc-ternary
pack   .button.b
pack   .button

set   gFm1 0
set   gFm2 0
frame .perf
label .perf.label -text "Maximal performance"
pack  .perf.label
frame .perf.p1 -padx 20
label .perf.p1.label -text "Direct order"
entry .perf.p1.entry -textvar gFm1 -state readonly
pack  .perf.p1.label
pack  .perf.p1.entry
pack  .perf.p1 -side left
frame .perf.p2 -padx 20
label .perf.p2.label -text "Indirect order"
entry .perf.p2.entry -textvar gFm2 -state readonly
pack  .perf.p2.label
pack  .perf.p2.entry
pack  .perf.p2 -side left
pack  .perf

set   qm1 0
set   qm22 0
frame .heat
label .heat.label -text "Maximal performance heat"
pack  .heat.label
frame .heat.h1 -padx 20
label .heat.h1.label -text "Direct order"
entry .heat.h1.entry -textvar qm1 -state readonly
pack  .heat.h1.label
pack  .heat.h1.entry
pack  .heat.h1 -side left
frame .heat.h2 -padx 20
label .heat.h2.label -text "Indirect order"
entry .heat.h2.entry -textvar qm2 -state readonly
pack  .heat.h2.label
pack  .heat.h2.entry
pack  .heat.h2 -side left
pack  .heat

proc draw-axes {} {
    global w h
    .plot.canvas create line 40 [expr $h - 20] 40 20 -arrow last
    .plot.canvas create line 20 [expr $h - 40] \
        [expr $w - 20] [expr $h - 40] -arrow last
    .plot.canvas create text 35 [expr $h - 31] -text 0
    .plot.canvas create text [expr $w - 31] [expr $h - 31] -text q
    .plot.canvas create text 27 33 -text g
    .plot.canvas create text 33 37 -text F
}

proc plot-area {} {
    global w h
    global gFm1 gFm2
    global qm1 qm2
    global mix
    global casc1 casc2
    set cnt 50
    set pmq [expr max($qm1, $qm2)]
    set pmg [expr max($gFm1, $gFm2)]
    set pw  [expr $w - 120]
    set ph  [expr $h - 120]
    .plot.canvas delete all
    draw-axes
    foreach i [list 1 2] {
	upvar 0 qm$i qm
	upvar 0 casc$i casc
	set q      0
	set q0     0
	set gF0    0
	set coords [list]
	while {$q < $qm - ($qm / $cnt)} {
	    set q    [expr $q + ($qm / $cnt)]
	    set cgF  [$casc performance-at $mix $q]
	    set pq   [expr 40 + round($q * $pw / $pmq)]
	    set pq0  [expr 40 + round($q0 * $pw / $pmq)]
	    set pgF  [expr round($h - $cgF * $ph / $pmg) - 40]
	    set pgF0 [expr round($h - $gF0 * $ph / $pmg) - 40]
	    lappend  coords $pq0 $pgF0 $pq $pgF
	    set q0   $q
	    set gF0  $cgF
	}
	.plot.canvas create text 55 [expr $pgF + 10] \
	    -text [format "%.3g" $cgF]
	.plot.canvas create line 40 $pgF $pq $pgF -dash -
	.plot.canvas create line $coords
    }
}

proc calculate {} {
    global gFm1 gFm2
    global qm1 qm2
    global casc1 casc2
    global mix
    set qm1 [$casc1 maximal-cost $mix]
    set qm2 [$casc2 maximal-cost $mix]
    set gFm1 [$casc1 maximal-performance $mix]
    set gFm2 [$casc2 maximal-performance $mix]
}

proc calc-ternary {} { 
    global x0 x1 x2
    global T0 T1 T2
    global r0 r1
    global k11 k12 k21 k22
    global BB1 BB2 BD1 BD2
    global swap1 swap2
    global eps
    global casc1 casc2
    global mix
  
    if {abs($x0 + $x1 + $x2 - 1) > $eps} {
	tk_messageBox -icon error \
	    -title Error -message "Concentration sum must be 1"
	return
    }
    if {abs($x0) < $eps || abs($x1) < $eps || abs($x2) < $eps} {
	tk_messageBox -icon error \
	    -title Error -message "Concentrations must not be 0"
	return
    }
    if {abs($T0) < $eps || abs($T1) < $eps || abs($T2) < $eps} {
	tk_messageBox -icon error \
	    -title Error -message "Temperatures must not be 0"
	return
    }	

    set c0    [component new $x0 $T0 $r0]
    set c1    [component new $x1 $T1 $r1]
    set c2    [component new $x2 $T2]
    set mix   [mixture   new [list $c0 $c1 $c2]]
    set col10 [column    new $k11 $BB1 $BD1]
    set col11 [column    new $k12 $BB2 $BD2]
    set col20 [column    new $k21 $BB1 $BD1]
    set col21 [column    new $k22 $BB2 $BD2]

    upvar 0 col1$swap1 ncol11
    upvar 0 col2[expr !$swap1] ncol12
    upvar 0 col2$swap2 ncol21
    upvar 0 col2[expr !$swap2] ncol22
    set casc1 [ternary-cascade new $ncol11 $ncol12 direct]
    set casc2 [ternary-cascade new $ncol21 $ncol22 indirect]

    if {[catch calculate]} {
	tk_messageBox -icon error \
	    -title Error -message "Inapropriate parameters"
	return
    }

    plot-area
}

set x0 0.5
set x1 0.3
set x2 0.2

set T0 393
set T1 438
set T2 458

set r0 50000
set r1 70000

set BB1 25000
set BB2 50000
set BD1 10000
set BD2 45000

set k11 13
set k12 11
set k21 15
set k22 13

draw-axes