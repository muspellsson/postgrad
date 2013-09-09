use PDL;
use PDL::GSL::MROOT;
use PDL::Graphics::Gnuplot;

$R = 8.31;

$gx0 = 0.38;
$gx1 = 0.2;

$x0 = $gx0;
$x1 = $gx1;
$x2 = 1 - $gx0 - $gx1;

$T0 = 393;
$T1 = 438;
$T2 = 458;

$beb11 = 20000;
$bed11 = 25000;
$bed12 = 60000;

$beb21 = 20000;
$bed21 = 25000;
$bed22 = 7000;

$k11 = 13;
$k21 = 15;
$k12 = 11;
$k22 = 13;

$r0 = 50000;
$r1 = 70000;
$r01 = ($r0 * $x0 + $r1 * $x1) / ($x0 + $x1);

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
    my $ka = -(1/($beb11*$T1**2) + 1/($bed11*$T0**2) + 2/($k11*$r0**2));
    $ka * $T0 / AG11();
}

sub ga12 {
    my $gbeb12 = @_[0];
    my $ka = -(1/($gbeb12*$T2**2) + 1/($bed12*$T1**2) + 2/($k12*$r1**2));
    $ka * $T1 / AG12();
}

sub a1f {
    my $gbeb12 = @_[0];
    a11() * ka12_11() - ga12($gbeb12);
}

sub a21 {
    my $ka = -(1/($beb21*($T2**2)) + 1/($bed21*$T1**2) + 2/($k21*$r01**2));
    $ka * $T1 / AG21();
}

sub ga22 {
    my $gbeb22 = @_[0];
    my $ka = -(1/($gbeb22*$T1**2) + 1/($bed22*$T0**2) + 2/($k22*$r0**2));
    $ka * $T0 / AG22();
}

sub a2f {
    my $gbeb22 = @_[0];
    (a21() * ka22_21() - ga22($gbeb22));
}

$beb12 = gslmroot_fsolver(pdl($bed12), \&a1f, {Epsabs => 1e-15});
$beb22 = gslmroot_fsolver(pdl($bed22), \&a2f, {Epsabs => 1e-15});

sub a12 {ga12($beb12);}

sub a22 {ga22($beb22);}

sub ra12 {
    $beb12 = gslmroot_fsolver(pdl($bed12), \&a1f, {Epsabs => 1e-15});
    ga12($beb12);
}

sub ra22 {
    $beb22 = gslmroot_fsolver(pdl($bed22), \&a2f, {Epsabs => 1e-15});
    ga22($beb22);
}

sub prev1 {
    my $x = @_[0];
    #printf "x0 = %g\n", $x0;
    my $v1 = b11() * b12() / (b12() + b11()*(1 - $x0));
    my $v2 = b21() * b22() / (b22() + b21()*(1 - $x2));
    $v1 - $v2;
}

sub prev2 {
    my $x = @_[0];
    my $v1 = b11()**2 * b12() / (a11() * (b12() + b11() * (1 - $x0)));
    my $v2 = b21()**2 * b22() / (a21() * (b22() + b21() * (1 - $x2)));
}

sub p11 {
    b11() * b12() / (b12() + b11()*(1 - $x0));
}

sub p12 {
    b21() * b22() / (b22() + b21()*(1 - $x2));
}

sub p21 {
    b11()**2 * b12() / (a11() * (b12() + b11() * (1 - $x0)));
}

sub p22 {
    b21()**2 * b22() / (a21() * (b22() + b21() * (1 - $x2)));
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

#for ($x2 = 0.1; $x2 < 0.9; $x2 = $x2 + 0.1) {
for ($k21 = 30; $k21 < 40; $k21++) {
$x2 = 0.3;

	$cs = pdl(1 - $x2);
	$xs = pdl();
	$ys = pdl();	
	for ($x0 = 0.01; 1 - $x0 - $x2 > 0; $x0 = $x0 + 0.01) {
		$x1 = 1 - $x2 - $x0;
		my $y;
		$xs = $xs->append($x0);
		$y  = pdl(gslmroot_fsolver(pdl($x0), 
			\&prev1,
			{Epsabs => 1e-15}));
    		$cs = $cs->append(1 - $x0 - $x2);
    		$ys = $ys->append($y);
		#printf "%g >= %g\n", p11(), p12();
		
		printf "###########################\n";
		printf "[CASE x0 = %g; x1 = %g; x2 = %g]\n", $x0 ,$x1, $x2;
                printf "r01 = %g\n", $r01;
                printf "AG11 = %g\n", AG11();
                printf "AG12 = %g\n", AG12();
                printf "AG21 = %g\n", AG21();
                printf "AG22 = %g\n", AG22();
                printf "b11 = %g\n", b11();
                printf "b12 = %g\n", b12();
                printf "b21 = %g\n", b21();
                printf "b22 = %g\n", b22();
                printf "a12 = %g * a11\n", ka12_11();
                printf "a22 = %g * a21\n", ka22_21();
                printf "a11 = %g\n", a11();
                printf "a12 = %g\n", ra12();
                printf "a21 = %g\n", a21();
                printf "a22 = %g\n", ra22();
                printf "beb12 = %g\n", $beb12;
                printf "beb22 = %g\n", $beb22;
                printf "gF1 = %g * q - %g * q^2\n", b1(), a1();
                printf "gF2 = %g * q - %g * q^2\n", b2(), a2();
                printf "\n"
	}

	#$ys1 = pdl();
	#for ($x0 = 0.01; 1 - $x1 - $x0 > 0; $x0 = $x0 + 0.01) {
	#    $x1 = 1 - $x2 - $x0;
	#    my $y;
	#    $y   = pdl(gslmroot_fsolver(pdl($x0), \&prev2, {Epsabs => 1e-15}));
	#    $ys1 = $ys1->append($y);
        #    printf "y = %g\n", $y;
	#    printf "%g >= %g", p21(), p22();
	#}

#printf $ys;
#printf $ys1;

gplot({terminal => 'pngcairo solid color font ",10" size 11in,8.5in',
	output => "tri$k21.png"},
	yrange => [0, 1-$x2],
	with => 'filledcurve', $xs, $ys,
	#with => 'lines', $xs, $ys1,
with => 'lines', $xs, pdl($xs*0, $cs));
}
