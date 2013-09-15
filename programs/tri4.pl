$R = 8.31;

$gF = 1;

$T0 = 393;
$T1 = 438;
$T2 = 458;

$x0 = 0.5;
$x1 = 0.3;
$x2 = 0.2;

$beb1 = 25000;
$bed1 = 10000;
$beb2 = 50000;
$bed2 = 45000;

$k11 = 13;
$k12 = 11;
$k21 = 15;
$k22 = 13;

$r0 = 50000;
$r1 = 70000;

sub r01{($r0 * $x0 + $r1 * $x1) / ($x0 + $x1);};

sub AG11 {($R * $T0 * ($x0 * log($x0) + (1 - $x0) * log(1 - $x0)));}

sub AG12 {($R * $T1 * ($x1 * log($x1) + (1-$x0-$x1) * log(1-$x0-$x1)))}

sub AG21 {($R * $T1 * ((1-$x0-$x1) * log(1-$x0-$x1) + ($x0 + $x1) * log($x0 + $x1)));}

sub AG22 {($R * $T0 * ($x0 * log($x0) + $x1 * log($x1)));}

sub b11 {- ($T1 - $T0) / ($T1 * AG11());}

sub b12 {- ($T2 - $T1) / ($T2 * AG12());}

sub b21 {- ($T2 - $T1) / ($T2 * AG21());}

sub b22 {- ($T1 - $T0) / ($T1 * AG22());}

sub ka12_11 {b12() ** 2 / (b11() ** 2 * (1 - $x0));}

sub ka22_21 {b22() ** 2 / (b21() ** 2 * (1 - $x2));}

sub a11 {
    my $ka = -(1/($beb1*$T1**2) + 1/($bed1*$T0**2) + 2/($k11*$r0**2));
    $ka * $T0 / AG11();
}

sub a12 {
    my $ka = -(1/($beb2*$T2**2) + 1/($bed2*$T1**2) + 2/($k12*$r1**2));
    my $v1 = 1/($beb2*$T2**2);
    my $v2 = 1/($bed2*$T1**2);
    my $v3 = 2/($k12*$r1**2);
    printf "%g %g %g\n", $v1, $v2, $v3;
    $ka * $T1 / AG12();
}

sub a21 {
    my $ka = -(1/($beb1*($T2**2)) + 1/($bed1*$T1**2) + 2/($k21*r01()**2));
    $ka * $T1 / AG21();
}

sub a22 {
    my $ka = -(1/($beb2*$T1**2) + 1/($bed2*$T0**2) + 2/($k22*$r0**2));
    $ka * $T0 / AG22();
}

sub b1 {
    b11()*b12()/(b12() + b11()*(1-$x0));
}

sub b2 {
    b21()*b22()/(b22() + b21()*(1-$x2));
}

sub a1 {
    a11()*b12()/(b12() + b11()*(1-$x0));
}

sub a2 {
    a21()*b22()/(b22() + b21()*(1-$x2));
}

sub q11 {
    (b11() - sqrt(b11()**2 - 4 * a11() * $gF)) / (2 * a11());
}

sub q12 {
    (b12() - sqrt(b12()**2 - 4 * a12() * $gF * (1 - $x0))) / (2 * a12());
}

sub q21 {
    (b21() - sqrt(b21()**2 - 4 * a21() * $gF)) / (2 * a21());
}

sub q22 {
    (b22() - sqrt(b22()**2 - 4 * a22() * $gF * (1-$x2))) / (2 * a21());
}

sub q1 {
    q11() + q12();
}

sub q2 {
    q21() + q22();
}

sub cons1 {
    my $l = b12()**2 / ((1 - $x0) * a12());
    my $r = b11()**2 / a11();
    printf "cons1 l = %g, r = %g\n", $l, $r;
    $l - $r;
}

sub cons2 {
    my $l = b22()**2 / ((1 - $x2) * a22());
    my $r = b21()**2 / a21();
    printf "cons2 l = %g, r = %g\n", $l, $r;
    $l - $r;
}

sub gFm1 {
    b11()**2 / (4 * a11());
}

sub gFm2 {
    b21()**2 / (4 * a21());
}

sub gFm11 {
    gFm1();
}

sub gFm21 {
    gFm2();
}

sub gFm12 {
    b12()**2 / (4 * a12());
}

sub gFm22 {
    b22()**2 / (4 * a22());
}

sub switch_cols {
    my $t;

    $t    = $beb1;
    $beb1 = $beb2;
    $beb2 = $t;
    $t    = $bed1;
    $bed1 = $bed2;
    $bed2 = $t;
    $t    = $k11;
    $k11  = $k12;
    $k12  = $t;
    $t    = $k21;
    $k21  = $k22;
    $k22  = $t;
}

printf "b11 = %g\n", b11();
printf "b12 = %g\n", b12();
printf "b21 = %g\n", b21();
printf "b22 = %g\n", b22();
printf "a11 = %g\n", a11();
printf "a12 = %g\n", a12();
printf "a21 = %g\n", a21();
printf "a22 = %g\n", a22();
printf "cons1 = %g\n", cons1();
printf "cons2 = %g\n", cons2();
printf "gFm1 = %g\n", gFm1();
#printf "gFm2 = %g\n", gFm2();
printf "q11 = %g\n", q11();
printf "q12 = %g\n", q12();
#printf "q21 = %g\n", q21();
#printf "q22 = %g\n", q22();
printf "q1 = %g\n", q1();
#printf "q2 = %g\n", q2();
printf "gFm11 = %g\n", gFm11();
printf "gFm12 = %g\n", gFm12();
#printf "gFm21 = %g\n", gFm21();
#printf "gFm22 = %g\n", gFm22();

if (0) {
printf "Switcheroooo!\n";
switch_cols();
printf "a11 = %g\n", a11();
printf "a12 = %g\n", a12();
printf "a21 = %g\n", a21();
printf "a22 = %g\n", a22();
printf "cons1 = %g\n", cons1();
printf "cons2 = %g\n", cons2();
#printf "gFm1 = %g\n", gFm1();
printf "gFm2 = %g\n", gFm2();
#printf "q11 = %g\n", q11();
#printf "q12 = %g\n", q12();
printf "q21 = %g\n", q21();
printf "q22 = %g\n", q22();
#printf "q1 = %g\n", q1();
printf "q2 = %g\n", q2();
#printf "gFm11 = %g\n", gFm11();
#printf "gFm12 = %g\n", gFm12();
printf "gFm21 = %g\n", gFm21();
printf "gFm22 = %g\n", gFm22();
}
