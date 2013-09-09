use PDL;
use PDL::GSL::MROOT;
use PDL::Graphics::Gnuplot;
use List::Util;

$R = 8.31;

$gF = 0.5;

$T0 = 393;
$T1 = 438;
$T2 = 458;

my $x0;
my $x1;
my $x2;

$beb11 = 20000;
$bed11 = 25000;
$beb12 = 10000;
$bed12 = 60000;

$beb21 = 100000;
$bed21 = 125000;
$beb22 = 90000;
$bed22 = 95000;

$k11 = 130;
$k21 = 100;
$k12 = 110;
$k22 = 80;

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
    my $ka = -(1/($beb11*$T1**2) + 1/($bed11*$T0**2) + 2/($k11*$r0**2));
    $ka * $T0 / AG11();
}

sub a12 {
    my $ka = -(1/($beb12*$T2**2) + 1/($bed12*$T1**2) + 2/($k12*$r1**2));
    $ka * $T1 / AG12();
}

sub a21 {
    my $ka = -(1/($beb21*($T2**2)) + 1/($bed21*$T1**2) + 2/($k21*r01()**2));
    $ka * $T1 / AG21();
}

sub a22 {
    my $ka = -(1/($beb22*$T1**2) + 1/($bed22*$T0**2) + 2/($k22*$r0**2));
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
    (b22() - sqrt(b22()**2 - 4 * a22() * $gF * $x2)) / (2 * a21());
}

sub q1 {
    q11() + q12();
}

sub q2 {
    q21() + q22();
}

sub check {
	$x1 = @_[0];
	$x2 = 1 - $x1 - $x0;
	q2() - q1();
}

sub acheck {
	$x1 = @_[0];
	$x2 = 1 - $x1 - $x0;
	$gF * (b2() - b1()) / (b2() * b1());
}

sub ls1 {
	$T2*($T1-$T0)*(1-$x0)*($x1*log($x1)+$x2*log($x2)) + $T0*($T2 - $T1)*($x0*log($x0)+(1-$x0)*log(1-$x0));
}

sub ls2 {
	$T2*($T1-$T0)*(($x0+$x1)*log($x0+$x1)+$x2*log($x2)) + $T0*($T2-$T1)*($x0*log($x0)+$x1*log($x1))*(1-$x2);
}

sub l {
	$x1 = @_[0];
	$x2 = 1 - $x1 - $x0;
	ls1() - ls2();
}

sub bisect {
	my $f   = @_[0];
	my $a   = @_[1];
	my $b   = @_[2];
	my $eps = @_[3];

	while (1) {
		my $c  = ($a + $b) / 2;
		my $fc = $f->($c);
		$fa = $f->($a);
		$fb = $f->($b);
		if ((abs($fc) < $eps) || (($b - $a) / 2 < $eps)) {
			return $c;
		}
		if ($fc * $fa > 0) {
			$a = $c;
		} else {
			$b = $c;
		}
   }
}

for ($bed11 = 20000; $bed11 < 21000; $bed11 = $bed11 + 20000)
#for ($k11 = 60; $k11 < 200; $k11 = $k11 + 20)
{
	$bed21 = $bed11 + 10000;
	$k21 = $k11 + 20;
	$cs = pdl(1);
	$xs = pdl();
	$ys = pdl();	
	$num = 0;
	for ($x0 = 0.001; $x0 < 0.999; $x0 = $x0 + 0.001) {
		$y = bisect(\&check, 0.001, 1-$x0-0.001, 1e-10);
		$xs = $xs->append($x0);		
    		$cs = $cs->append(1 - $x0);
    		$ys = $ys->append($y);
		$num++;
	}	


	$xs = $xs->slice('1:-1');
	$ys = $ys->slice('1:-1');
	$cs = $cs->slice('1:-1');
	
	for ($i = 0; $i < $num; $i++) {
	    $x = $xs->index($i);
	    $y = $ys->index($i);
	    $x *= 4.5;
	    $y *= 4.5;
	    printf "($x, $y) ";
	}

#	gplot({terminal => 'pngcairo solid color font ",10" size 11in,8.5in',
#	       output  => "trik$num.png",
#	       title   => "",#"k_{11} = $k11; k_{21} = $k21",
#	       xlabel  => "x_0",
#	       ylabel  => "x_1"},
#	      yrange => [0, 1-$x2],
#	      with => 'lines', $xs, $ys,
#	      with => 'lines', $xs, pdl($xs*0, $cs));
}

if (0) {
$num = 0;
$xs = pdl();
$ys = pdl();
$cs = pdl();
$ys1 = pdl();
for ($x0 = 0.001; $x0 < 0.999; $x0 = $x0 + 0.001) {
	$y  = bisect(\&acheck, 0.001, 1-$x0-0.001, 1e-10);
	$xs = $xs->append($x0);		
	$cs = $cs->append(1 - $x0);
	$ys = $ys->append($y);
	$y1  = bisect(\&l, 0.001, 1-$x0-0.001, 1e-10);
	$ys1 = $ys1->append($y1);
	$num++;
}
$xs = $xs->slice('1:-1');
$ys = $ys->slice('1:-1');
$cs = $cs->slice('1:-1');
$ys1 = $ys1->slice('1:-1');
for ($i = 0; $i < $num; $i++) {
    $x = $xs->index($i);
    $y = $ys->index($i);
$x *= 4.5;
$y *= 4.5;
    printf "($x, $y) ";
}
}
#gplot({terminal => 'pngcairo solid color font ",10" size 11in,8.5in',
#	output  => "rev.png",
#	title   => "",
#	xlabel  => "x_0",
#	ylabel  => "x_1"},
#	yrange => [0, 1-$x2],
#	with => 'lines', $xs, $ys,
#	with => 'lines', $xs, $ys1,
#	with => 'lines', $xs, pdl($xs*0, $cs));
