package require Tcl 8.6
package require TclOO

oo::class create component {
    variable x
    variable T
    variable r
    # I represent a component of some mixture
    constructor {cx cT {cr 0}} {
	# Concentration
	my variable x
	set x $cx
	# Boiling temperature
	my variable T
	set T $cT
	# Molar boiling heat
	my variable r
	set r $cr
    }
    
    method concentration {} {
	my variable x
	return $x
    }

    method temperature {} {
	my variable T
	return $T
    }

    method boiling-heat {} {
	my variable r
	return $r
    }
}

oo::class create mixture {
    variable R
    variable n
    # I represent a mixture
    constructor {components} {
	# Gas constant
	my variable R
	set R 8.3144621
	# Number of components
	my variable n 
	set n [llength $components]
	for {set i 0} {$i < $n} {incr i} {
	    my variable c$i
	    set c$i [lindex $components $i]
	}
    }
	  
    method separation-energy {m} {
	my variable n
	my variable R
	set upper 0
	set lower 0
	for {set i 0} {$i < $n} {incr i} {
	    my variable c$i
	    upvar 0 c$i c
	    set x [$c concentration]
	    if {$i <= $m} {
		set upper [expr $upper + $x] 
	    } else {
		set lower [expr $lower + $x]
	    }
	}
	upvar 0 c$m c
	set T [$c temperature]
	return [expr $R * $T * ($upper * log($upper) + $lower * log($lower))]
    }
    
    method component-concentration {m} {
	my variable c$m
	upvar 0 c$m c
	return [$c concentration]
    }

    method component-temperature {m} {
	my variable c$m
	upvar 0 c$m c
	return [$c temperature]
    }

    method submixture-boiling-heat {m1 m2} {
	set num   0
	set denom 0
	for {set i $m1} {$i <= $m2} {incr i} {
	    my variable c$i
	    upvar 0 c$i c
	    set r [$c boiling-heat]
	    set x [$c concentration]
	    set num   [expr $num + $r * $x]
	    set denom [expr $denom + $x]
	}
	return [expr $num / $denom]
    }

    method separate-to {m} {
	set newmix [list]
	for {set i 0} {$i <= $m} {incr i} {
	    my variable c$i
	    upvar 0 c$i c
	    lappend newmix $c
	}
	return [mixture new $newmix]
    }

    method separate-from {m} {
	my variable n
	set newmix [list]
	for {set i $m} {$i < $n} {incr i} {
	    my variable c$i
	    upvar 0 c$i c
	    lappend newmix $c
	}
	return [mixture new $newmix]
    }
}

oo::class create column {
    variable k
    variable betaB
    variable betaD
    # I represent the distillation column
    constructor {mk hbetaB hbetaD} {
	# Mass transfer coefficient
	my variable k
	set k $mk
	# Heat transfer coefficient in reboiler
	my variable betaB
	set betaB $hbetaB
	# Heat transfer coefficient in reflux drum
	my variable betaD
	set betaD $hbetaD
    }

    method reversible-efficiency {s m} {
	set TD [$s component-temperature $m]
	set TB [$s component-temperature [expr $m + 1]]
	set A  [$s separation-energy $m]
	return [expr - ($TB - $TD) / ($TB * $A)]
    }

    method irreversibility {s m} {
	my variable k
	my variable betaB
	my variable betaD
	set TD [$s component-temperature $m]
	set TB [$s component-temperature [expr $m + 1]]
	set r  [$s submixture-boiling-heat 0 $m]
	set A  [$s separation-energy $m]
	set p1 [expr 1 / ($betaB * pow($TB, 2))]
	set p2 [expr 1 / ($betaD * pow($TD, 2))]
	set p3 [expr 2 / ($k * pow($r, 2))]
	return [expr - ($p1 + $p2 + $p3) * $TD / $A]
    }

    # TODO: Remove this
    method set-k {newk} {
	my variable k
	set k $newk
    }

    method maximal-performance {s m} {
	set a [my irreversibility $s $m]
	set b [my reversible-efficiency $s $m]
	return [expr pow($b, 2) / (4 * $a)]
    }

    method maximal-cost {s m} {
	set a [my irreversibility $s $m]
	set b [my reversible-efficiency $s $m]
	return [expr $b / (2 * $a)]
    }
}

oo::class create ternary-cascade {
    # I represent a two-column cascade separating ternary mixture
    variable col1
    variable col2
    variable order
    constructor {c1 c2 m} {
	my variable col1
	set col1 $c1
	my variable col2
	set col2 $c2
	my variable order
	if {[string equal $m direct]} {
	    set order 0
	} else {
	    set order 1
	}
    }

    method key-component-concentration {s} {
	my variable order
	if {$order == 0} {
	    return [$s component-concentration 0]
	} else {
	    return [$s component-concentration 2]
	}
    }

     method intermediate-separate {s} {
	my variable order
	if {$order == 0} {
	    return [$s separate-from 1]
	} else {
	    return [$s separate-to 1]
	}
    }
    
    method maximal-performance {s} {
	my variable col1
	my variable col2
	my variable order
	set g1 0
	set g2 0
	# Distilled mixture
	set d  0
	# Lonely component
	set x  0
	if {$order == 0} {
	    set g1 [$col1 maximal-performance $s 0]
	    set d  [$s separate-from 1]
	} else {
	    set g1 [$col1 maximal-performance $s 1]
	    set d  [$s separate-to 1]
	}
	set d  [my intermediate-separate $s]
	set x  [my key-component-concentration $s]
	set g2 [$col2 maximal-performance $d 0]
	if {$g1 * (1 - $x) < $g2} {
	    return $g1
	} else {
	    return [expr $g2 / (1 - $x)]
	}
    }

    method maximal-cost {s} {
	my variable order
	my variable col1
	my variable col2
	set x  [my key-component-concentration $s]
	set g  [my maximal-performance $s]
	set d  [my intermediate-separate $s]
	set a1 [$col1 irreversibility $s $order]
	set b1 [$col1 reversible-efficiency $s $order]
	set a2 [$col2 irreversibility $d 0]
	set b2 [$col2 reversible-efficiency $d 0]
	set ks [expr 1 - $x]
	set q1 [expr ($b1 - sqrt(pow($b1, 2) - 4 * $a1 * $g)) / (2 * $a1)]
	set q2 [expr ($b2 - sqrt(pow($b2, 2) - 4 * $a2 * $g * $ks)) / (2 * $a2)]
	return [expr $q1 + $q2]
    }

    method performance-at {s cost} {
	my variable order
	my variable col1
	my variable col2
	if {$cost > [my maximal-cost $s]} { 
	    return 0
	}
	set x [my key-component-concentration $s]
	set d  [my intermediate-separate $s]
	set a1 [$col1 irreversibility $s $order]
	set b1 [$col1 reversible-efficiency $s $order]
	set a2 [$col2 irreversibility $d 0]
	set b2 [$col2 reversible-efficiency $d 0]
	set ks [expr 1 - $x]
	# Solving quadratic equation
	set qea [expr $a2 - $ks * $a1]
	set qeb [expr $ks * $b1 + $b2 - 2 * $a2 * $cost]
	set qec [expr $a2 * pow($cost, 2) - $b2 * $cost]
	set qed [expr pow($qeb, 2) - 4 * $qea * $qec]
	set q   [expr (- $qeb + sqrt($qed)) / (2 * $qea)]
	return  [expr $b1 * $q - $a1 * pow($q, 2)]
    }
}

if 0 {
component create c0 0.5 393 50000
component create c1 0.3 438 70000
component create c2 0.2 458
mixture create m [list c0 c1 c2]

puts [format "AG11 = %g" [m separation-energy 0]]
puts [format "AG21 = %g" [m separation-energy 1]]
set m1 [m separate-from 1]
set m2 [m separate-to 1]
mixture create m1 [list c1 c2]
mixture create m2 [list c0 c1]
puts [format "AG12 = %g" [$m1 separation-energy 0]]
puts [format "AG22 = %g" [$m2 separation-energy 0]]
column create col1 13 25000 10000
column create col2 11 50000 45000
column create col3 15 25000 10000
column create col4 13 50000 45000
ternary-cascade create casc1 col1 col2 0
ternary-cascade create casc2 col3 col4 1
puts [format "b11 = %g" [col1 reversible-efficiency m 0]]
puts [format "b12 = %g" [col2 reversible-efficiency $m1 0]]
puts [format "a11 = %g" [col1 irreversibility m 0]]
puts [format "a12 = %g" [col2 irreversibility $m1 0]]
puts [format "a21 = %g" [col3 irreversibility m 1]]
puts [format "a22 = %g" [col4 irreversibility $m2 0]]
puts [format "gFm11 = %g" [col1 maximal-performance m 0]]
puts [format "gFm12 = %g" [col2 maximal-performance $m1 0]]
puts [format "gFm21 = %g" [col3 maximal-performance m 1]]
puts [format "gFm22 = %g" [col4 maximal-performance $m2 0]]
puts [format "gFm1 = %g" [casc1 maximal-performance m]]
puts [format "gFm2 = %g" [casc2 maximal-performance m]]
puts [format "qm1 = %g" [casc1 maximal-cost m]]
puts [format "qm2 = %g" [casc2 maximal-cost m]]
puts [format "gFm1 = %g" [casc1 performance-at m [casc1 maximal-cost m]]]
puts [format "gFm2 = %g" [casc2 performance-at m [casc2 maximal-cost m]]]
}