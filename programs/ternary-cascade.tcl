package require Tk 8.6
package require msgcat
namespace import msgcat::*

mcset ru Concentrations Концентрации
mcset ru "Distillation of a ternary mixture" \
    "Разделение трехкомпонентной смеси"
mcset ru "Evaporation temperatures, K" "Температуры кипения, K"
mcset ru "Molar heats of vaporization, J/mol" \
    "Мольная теплота парообразования, Дж/моль"
mcset ru "Heat transfer coefficients, W/K" \
    "Коэффициенты теплопереноса, Вт/K"
mcset ru "Mass transfer coefficient, (mol²⋅K) / (J⋅s)" \
    "Коэффициенты массопереноса, (моль²⋅K) / (Дж⋅c)"
mcset ru "Swap columns for direct order" \
    "Переставить колонны для\nпрямого порядка"
mcset ru "Swap columns for indirect order" \
    "Переставить колонны для\nнепрямого порядка"
mcset ru "Plot attainability region boundaries" \
    "Построить границы областей реализуемости"
mcset ru "Max. performance, mol/s" \
    "Макс. производительность, моль/с"
mcset ru "Max. energy consumption, J" \
    "Макс. затраты, Дж"
mcset ru "Direct order" "Прямой пор."
mcset ru "Indirect order" "Непрямой пор."
mcset ru "Concentration sum must be 1" \
    "Сумма концентраций должна быть равна единице"
mcset ru "Concentrations must not be 0" \
    "Концентрации должны быть отличны от нуля"
mcset ru "Temperatures must be positive" \
    "Температуры должны быть положительными"
mcset ru "Components must be ordered by T" \
    "Компоненты должны быть упорядочены по температурам кипения"
mcset ru "Inapropriate parameters" \
    "Каскад нереализуем при таких значениях параметров"

source [file join [file dirname [info script]] distillation-0.1.tm]

encoding system utf-8

if {![string equal $tcl_platform(os) "Windows NT"]} {
    ttk::style theme use clam
}

# Epsilon
set eps 1e-15

# Canvas and it's frame
set    w 440
set    h 440
ttk::frame  .plot
canvas .plot.canvas -bg white -width $w -height $h
pack   .plot.canvas
pack   .plot -side left

# ==== Mixture ====

# Mixture parameters
set mIdcs [list 0 1 2]
set lidcs [list ₀ ₁ ₂]

wm title . [mc "Distillation of a ternary mixture"]
wm resizable . false false

# Concentrations
ttk::labelframe .xs -text [mc Concentrations] \
    -labelanchor n
foreach idx $mIdcs {
    set   x$idx 0
    ttk::frame .xs.x$idx
    ttk::label .xs.x$idx.label -text x[lindex $lidcs $idx]
    pack  .xs.x$idx.label
    ttk::entry .xs.x$idx.entry -textvar x$idx -width 18 \
	-validate key -validatecommand {string is double %P} \
	-justify right
    pack  .xs.x$idx.entry
    pack  .xs.x$idx -side left -expand 1
}
pack .xs -fill x

# Boiling temperatures
ttk::labelframe .ts -text [mc "Evaporation temperatures, K"] \
    -labelanchor n
foreach idx $mIdcs {
    set   T$idx 0
    ttk::frame .ts.t$idx
    ttk::label .ts.t$idx.label -text T[lindex $lidcs $idx]
    pack  .ts.t$idx.label
    ttk::entry .ts.t$idx.entry -textvar T$idx -width 18 \
	-validate key -validatecommand {string is double %P} \
	-justify right
    pack  .ts.t$idx.entry
    pack  .ts.t$idx -side left -expand 1
}
pack .ts -fill x

# Molar boiling heats
set   bhIdcs [list 0 1]
ttk::labelframe .bhs -text [mc "Molar heats of vaporization, J/mol"] \
    -labelanchor n
foreach idx $bhIdcs {
    set   r$idx 0
    ttk::frame .bhs.r$idx
    ttk::label .bhs.r$idx.label -text r[lindex $lidcs $idx]
    pack  .bhs.r$idx.label
    ttk::entry .bhs.r$idx.entry -textvar r$idx \
	-validate key -validatecommand {string is double %P}
    pack  .bhs.r$idx.entry
    pack  .bhs.r$idx -side left -expand 1
}
pack .bhs -fill x 

# ==== Columns ====

# Heat transfer coefficients
set   htIdcs [list B1 D1 B2 D2]
set   hidcs  [list B₁ D₁ B₂ D₂]
set   i      0
ttk::labelframe .htcs -text [mc "Heat transfer coefficients, W/K"] \
    -labelanchor n
foreach idx $htIdcs {
    set   B$idx 0
    ttk::frame .htcs.b$idx
    ttk::label .htcs.b$idx.label -text β[lindex $hidcs $i]
    pack  .htcs.b$idx.label
    ttk::entry .htcs.b$idx.entry -textvar B$idx -width 13 \
	-validate key -validatecommand {string is double %P}
    pack  .htcs.b$idx.entry
    pack  .htcs.b$idx -side left -expand 1
    incr  i
}
pack .htcs -fill x

# Mass transfer coefficients
set   mtIdcs [list 11 12 21 22]
set   kidcs  [list ₁₁ ₁₂ ₂₁ ₂₂]
set   i      0
ttk::labelframe .mtcs -text [mc "Mass transfer coefficient, (mol²⋅K) / (J⋅s)"] \
    -labelanchor n
foreach idx $mtIdcs {
    set   k$idx 0
    ttk::frame .mtcs.k$idx
    ttk::label .mtcs.k$idx.label -text k[lindex $kidcs $i]
    pack  .mtcs.k$idx.label
    ttk::entry .mtcs.k$idx.entry -textvar k$idx -width 13 \
	-validate key -validatecommand {string is double %P}
    pack  .mtcs.k$idx.entry
    pack  .mtcs.k$idx -side left -expand 1
    incr  i
}
pack .mtcs -fill x

set         swap1 0
set         swap2 0
ttk::frame       .swap
ttk::checkbutton .swap.b1 -text [mc "Swap columns for direct order"] \
    -variable swap1
ttk::checkbutton .swap.b2 -text [mc "Swap columns for indirect order"] \
    -variable swap2
pack        .swap.b1 -side left
pack        .swap.b2
pack        .swap -fill x

ttk::frame  .button
ttk::button .button.b -text [mc "Plot attainability region boundaries"] \
    -command calc-ternary
pack   .button.b 
pack   .button -fill x


set   gFm1 0
set   gFm2 0
ttk::frame .max
ttk::labelframe .max.perf -text [mc "Max. performance, mol/s"] \
    -labelanchor n
ttk::frame .max.perf.p1 
ttk::label .max.perf.p1.label -text [mc "Direct order"]
ttk::entry .max.perf.p1.entry -textvar gFm1 -state readonly -width 13
pack  .max.perf.p1.label
pack  .max.perf.p1.entry
pack  .max.perf.p1 -side left
ttk::frame .max.perf.p2
ttk::label .max.perf.p2.label -text [mc "Indirect order"]
ttk::entry .max.perf.p2.entry -textvar gFm2 -state readonly -width 13
pack  .max.perf.p2.label
pack  .max.perf.p2.entry
pack  .max.perf.p2 -side left
pack  .max.perf -side left

set   qm1 0
set   qm2 0
ttk::labelframe .max.heat -text [mc "Max. energy consumption, J"] \
    -labelanchor n
ttk::frame .max.heat.h1 
ttk::label .max.heat.h1.label -text [mc "Direct order"]
ttk::entry .max.heat.h1.entry -textvar qm1 -state readonly -width 13
pack  .max.heat.h1.label
pack  .max.heat.h1.entry
pack  .max.heat.h1 -side left
ttk::frame .max.heat.h2
ttk::label .max.heat.h2.label -text [mc "Indirect order"]
ttk::entry .max.heat.h2.entry -textvar qm2 -state readonly -width 13
pack  .max.heat.h2.label
pack  .max.heat.h2.entry
pack  .max.heat.h2 -side left
pack  .max.heat -side left
pack  .max -fill x -fill y


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
    set cnt 8
    set pmq [expr max($qm1, $qm2)]
    set pmg [expr max($gFm1, $gFm2)]
    set pw  [expr $w - 160]
    set ph  [expr $h - 120]
    .plot.canvas delete all
    draw-axes
    foreach i [list 1 2] {
	upvar 0 qm$i  qm
	upvar 0 gFm$i gFm
	upvar 0 casc$i casc
	set q      0
	set q0     0
	set gF0    0
	set coords [list]
	while {$q < $qm} {
	    set q    [expr $q + ($qm / $cnt)]
	    if  {$q > $qm} { break }
	    set cgF  [$casc performance-at $mix $q]
	    set pq   [expr 40 + round($q * $pw / $pmq)]
	    set pq0  [expr 40 + round($q0 * $pw / $pmq)]
	    set pgF  [expr round($h - $cgF * $ph / $pmg) - 40]
	    set pgF0 [expr round($h - $gF0 * $ph / $pmg) - 40]	   
	    lappend  coords $pq0 $pgF0 $pq $pgF
	    set q0   $q
	    set gF0  $cgF
	}
	.plot.canvas create text [expr $pq + 5] $pgF \
	    -text [format "(%.3g; %.5g)" $gFm $qm] -anchor w
	.plot.canvas create line 40 $pgF $pq $pgF -dash -
	.plot.canvas create line $pq [expr $h - 40] $pq $pgF -dash -
	.plot.canvas create line $coords -smooth true
    }
}

proc calculate {} {
    global gFm1 gFm2
    global qm1 qm2
    global casc1 casc2
    global mix
    set qm1  [format "%.5g" [$casc1 maximal-cost $mix]]
    set qm2  [format "%.5g" [$casc2 maximal-cost $mix]]
    set gFm1 [format "%.5g" [$casc1 maximal-performance $mix]]
    set gFm2 [format "%.5g" [$casc2 maximal-performance $mix]]
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
	    -title Error -message [mc "Concentration sum must be 1"]
	return
    }
    if {abs($x0) < $eps || abs($x1) < $eps || abs($x2) < $eps} {
	tk_messageBox -icon error \
	    -title Error -message [mc "Concentrations must not be 0"]
	return
    }
    if {$T0 <= $eps || $T1 <= $eps || $T2 <= $eps} {
	tk_messageBox -icon error \
	    -title Error -message [mc "Temperatures must be positive"]
	return
    }
    if {!(($T0 < $T1) && ($T1 < $T2))} {
	tk_messageBox -icon error \
	    -title Error -message [mc "Components must be ordered by T"]
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
	    -title Error -message [mc "Inapropriate parameters"]
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