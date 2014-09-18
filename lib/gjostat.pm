package gjostat;

# This is a SAS component.

use strict;
use Carp qw( confess );

sub usage
{
<<'End_of_Usage';
gjostat.pm - perl functions for dealing with statistics

$var = rand_normal()

$mean = mean( @x )
( $mean, $stdev ) = mean_stddev( @x )
$cc = correl_coef( \@x, \@y )
$Z  = correl_coef_z_val( $cc, $n_samples )

$median = median( @list )
$median = general_median( $fraction, @list )

( $chi_sqr, $df, $n ) = chi_square( \@expected, \@observed )
( $chi_sqr, $df, $n ) = contingency_chi_sqr(  @row_refs )
( $chi_sqr, $df, $n ) = contingency_chi_sqr( \@row_refs )
( $chi_sqr, $df, $n ) = contingency_chi_sqr_2( \@row1, \@row2 )
( $chi_sqr, $df, $n ) = contingency_chi_sqr_2( \@row_refs )

$p_value = chisqr_prob( $chisqr, $df )
$chisqr  = chisqr_critical_value( $p_value, $df )

$coef = binomial_coef( $n, $m )
$prob = binomial_prob_eq_m( $n, $m, $p )
$prob = binomial_prob_le_m( $n, $m, $p )
$prob = binomial_prob_ge_m( $n, $m, $p )

$ln_coef = ln_binomial_coef( $n, $m )
$ln_prob = ln_binomial_prob_eq_m( $n, $m, $p )

$m = binomial_critical_value_m_ge( $n, $p, $P )
$m = binomial_critical_value_m_le( $n, $p, $P )

$prob = std_normal_ge_z( $z )
$prob = std_normal_le_z( $z )

$z = std_normal_critical_value_z_ge( $P )
$z = std_normal_critical_value_z_le( $P )

$prob = poisson_prob_eq_n( $n, $mu )
$prob = poisson_prob_le_n( $n, $mu )
$prob = poisson_prob_ge_n( $n, $mu )

$fact    = factorial( $n )
$ln_fact = ln_factorial( $n )

Notes:  Exponentiation by int uses **.
        Should consider explicit multiplication

        No checking for integer values is performed

End_of_Usage
}


require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
        rand_normal
        mean
        mean_stddev
        correl_coef
        correl_coef_z_val
        median
        general_median
        chi_square
        contingency_chi_sqr
        contingency_chi_sqr_2
        chisqr_prob
        chisqr_critical_value
        binomial_coef
        binomial_prob_eq_m
        binomial_prob_le_m
        binomial_prob_ge_m
        binomial_critical_value_m_ge
        binomial_critical_value_m_le
        ln_binomial_coef
        ln_binomial_prob_eq_m
        std_normal_le_z
        std_normal_ge_z
        std_normal_critical_value_z_ge
        std_normal_critical_value_z_le
        poisson_prob_eq_n
        poisson_prob_le_n
        poisson_prob_ge_n
        factorial
        ln_factorial
        );


#-----------------------------------------------------------------------------
#  $var = rand_normal()
#-----------------------------------------------------------------------------

sub rand_normal
{
    my $sum = -6;
    for ( my $i = 1; $i <= 12; $i++ ) { $sum += rand }
    $sum;
}


#-----------------------------------------------------------------------------
#  $mean = mean( @x )
#-----------------------------------------------------------------------------
sub mean
{
    my $n   = 0;
    my $sum = 0;
    foreach ( @_ ) { if ( defined $_ ) { $n++; $sum += $_ } }

    $n ? $sum / $n : undef;
}


#-----------------------------------------------------------------------------
#  ($mean, $stdev) = mean_stddev( @x )
#-----------------------------------------------------------------------------
sub mean_stddev
{
    my ( $n, $sum, $sum2 ) = ( 0, 0, 0 );
    foreach ( @_ ) { if ( defined $_ ) { $n++; $sum += $_; $sum2 += $_ * $_ } }
    return $n ? ( $sum, undef) : ( undef, undef ) if $n < 2;

    my $x = $sum / $n;
    ( $x, sqrt( ( $sum2 - $sum * $x ) / ( $n - 1 ) ) );
}


#-----------------------------------------------------------------------------
#  $cc = correl_coef( \@x, \@y )
#-----------------------------------------------------------------------------
sub correl_coef
{
    my ($xref, $yref) = @_;
    $xref && ref $xref eq 'ARRAY' && $yref && ref $yref eq 'ARRAY'
        or confess "gjostat::correl_coef() called with invalid parameter types.\n";
    (@$xref == @$yref) || confess "gjostat::correl_coef() called with lists of different lengths\n";
    (@$xref > 2) || return undef;
    my (@x) = @$xref;
    my (@y) = @$yref;
    my $n = @x;

    my ($xsum, $x2sum, $ysum, $y2sum, $xysum) = (0) x 5;
    my ($i, $xi, $yi);

    for ($i = 1; $i <= $n; $i++)
{
        $xi = shift @x; $xsum += $xi; $x2sum += $xi*$xi;
        $yi = shift @y; $ysum += $yi; $y2sum += $yi*$yi;
                                      $xysum += $xi*$yi;
    }

    my $xsd = sqrt( ($x2sum - ($xsum*$xsum/$n)) / ($n - 1) );
    my $ysd = sqrt( ($y2sum - ($ysum*$ysum/$n)) / ($n - 1) );
    if (($xsd == 0) || ($ysd == 0)) { return undef }
    ( $xysum - $xsum * $ysum / $n ) / ( $xsd * $ysd * ( $n - 1 ) );
}


#-----------------------------------------------------------------------------
#  $Z = correl_coef_z_val( $cc, $n_samples )
#
#  arctanh(x) = ln( ( 1 + x ) / ( 1 - x ) ) / 2
#-----------------------------------------------------------------------------
sub correl_coef_z_val
{
    my( $cc, $n_samples ) = @_;
    defined( $cc ) && $cc >= -1 && $cc <= 1 or return undef;
    defined( $n_samples ) && $n_samples > 2 or return undef;
    sqrt( $n_samples - 3 ) * 0.5 * log( ( 1.000000001 + $cc ) / ( 1.000000001 - $cc ) );
}


#-----------------------------------------------------------------------------
#  Value that 50% of n sample values are below. Discarding undef.
#
#     $median = median( @list )
#-----------------------------------------------------------------------------
sub median
{
    my @list = sort { $a <=> $b } grep { defined $_ } @_
        or return undef;

    #  Find midpoint for odd and even cases
    ( @list % 2 ) ? $list[ int( @list/2 ) ]
                  : 0.5 * ( $list[ @list/2 ] + $list[ @list/2 + 1 ] );
}


#-----------------------------------------------------------------------------
#  Value that fraction of n sample values are below
#
#     $median = general_median( $fraction, @list )
#
#  Musings on splitting the intervals between sample values
#-----------------------------------------------------------------------------
#                                     n
#        ----------------------------------------------------------------
#   fr     2      3        4          5            6              7
#------------------------------------------------------------------------
#  0.25   * 1   0*1 2   0*1 2 3   0*1 2 3 4   0 * 2 3 4 5   0 1*2 3 4 5 6
#  0.50   0*1   0 * 2   0 1*2 3   0 1 * 3 4   0 1 2*3 4 5   0 1 2 * 4 5 6
#  0.75   0 *   0 1*2   0 1 2*3   0 1 2 3*4   0 1 2 3 * 5   0 1 2 3 4*5 6
#------------------------------------------------------------------------

sub general_median
{
    my $fr = shift;
    ( defined( $fr ) && ( $fr > 0 ) && ( $fr < 1 ) )
        or confess "gjostat::general_median called with bad fraction: $fr\n";

    my @list = sort { $a <=> $b } grep { defined $_ } @_;
    my $n = @list;
    my $nbelow = $n * $fr;
    ( $n > 1 ) && ( $nbelow - 0.5 >=  0 )
               && ( $nbelow + 0.5 <= $n )
               || return undef;

    my $ibelow = int($nbelow - 0.5);
    my $frac   = $nbelow - 0.5 - $ibelow;

    my $median = $list[ $ibelow ];
    $median += $frac * ( $list[ $ibelow+1 ] - $median )  if $frac;

    $median;
}


#-----------------------------------------------------------------------------
#  Find the chi-square value for an expected value (or frequency) list and
#  an observed list (expected values need not be normalized):
#
#      ( $chi_sqr, $df, $n ) = chi_square( \@expected, \@observed )
#
#-----------------------------------------------------------------------------

sub chi_square
{
    my ( $expect, $obs ) = @_;
    $expect && ref $expect eq 'ARRAY' && $obs && ref $obs eq 'ARRAY'
        or confess "gjostat::chi_square() called with invalid parameter types.";
    ( @$expect > 1 ) && ( @$expect == @$obs ) || return ( 0, 0, 0 );

    my ( $sum1, $sum2 ) = ( 0, 0 );
    foreach ( @$expect ) { $sum1 += $_ }
    foreach ( @$obs    ) { $sum2 += $_ }
    ( $sum1 > 0 && $sum2 > 0 ) || return ( 0, 0, 0 );
    my $scale = $sum2 / $sum1;

    my ( $e, $o );
    my ( $chisqr, $df ) = ( 0, -1 );
    my $i = 0;
    foreach $e ( map { $scale * $_ } @$expect )
    {
        $o = $obs->[ $i++ ]; 
        if ( $e > 0 )
        {
            $o -= $e;
            $chisqr += $o * $o / $e;
            $df++;
        }
        elsif ( $o > 0 )
        {
            confess "gjostat::chi_sqr called with invalid expected value\n"
        }
    }

    ( $df > 0 ) ? ( $chisqr, $df, $sum2 ) : ( 0, 0, 0 )
}


#-----------------------------------------------------------------------------
#  Find the chi-square value for a contingency table:
#
#      ( $chi_sqr, $df, $n ) = contingency_chi_sqr(  @row_refs )
#      ( $chi_sqr, $df, $n ) = contingency_chi_sqr( \@row_refs )
#
#-----------------------------------------------------------------------------

sub contingency_chi_sqr
{
    if ( ( @_ == 1 ) && ( ref( $_[0]      ) eq "ARRAY" )
                     && ( ref( $_[0]->[0] ) eq "ARRAY" )
       ) { @_ = @{$_[0]} }

    ( @_ > 1 ) || return (0, 0, 0);
    ref( $_[0] ) eq "ARRAY"
        || confess "gjostat::contingency_chi_sqr: arguements must be ARRAY references\n";

    my $ncol = @{ $_[0] };
    my ( @rows, @csum, @rsum );
    my $sum = 0;
    my $n;
    my $row;

    foreach $row ( @_ )
    {
        ref( $row ) eq "ARRAY"
            || confess "gjostat::contingency_chi_sqr: arguements must be ARRAY references\n";
        ( @$row == $ncol )
            || confess "gjostat::contingency_chi_sqr:  all rows must have same number of items\n";

        my $rsum = 0;
        for (my $i = 0; $i < $ncol; $i++)
        {
            $n = $row->[ $i ];
            $rsum += $n;
            $csum[ $i ] += $n;
        }
        if ( $rsum > 0 )
        {
            push @rows, $row;
            push @rsum, $rsum;
            $sum += $rsum;
        }
    }

    $ncol = 0;
    foreach ( @csum ) { $ncol++ if $_ > 0 }
    ( @rows > 1 ) && ( $ncol > 1 ) || return (0, 0, 0);

    my $chi_sqr = 0;
    my ( $e, $rsum, $c );
    foreach $row ( @rows )
    {
        $rsum = shift @rsum;

        for (my $i = 0; $i < $ncol; $i++)
        {
            ( ( $c = $csum[ $i ] ) > 0 ) || next;
            $e = $rsum * $c / $sum;
            $chi_sqr += ( $row->[ $i ] - $e )**2 / $e;
        }
    }

    ( $chi_sqr, ($ncol-1) * (@rows-1), $sum )
}


#-----------------------------------------------------------------------------
#  Find the chi-square value for a 2-row contingency table:
#
#      ( $chi_sqr, $df, $n ) = contingency_chi_sqr_2( \@row1, \@row2 )
#      ( $chi_sqr, $df, $n ) = contingency_chi_sqr_2( \@row_refs )
#
#-----------------------------------------------------------------------------

sub contingency_chi_sqr_2
{
    if ( ( @_ == 1 ) && ( ref( $_[0]      ) eq "ARRAY" )
                     && ( ref( $_[0]->[0] ) eq "ARRAY" )
       ) { @_ = @{$_[0]} }

    ( @_ == 2 ) && ( ref( $_[0] ) eq "ARRAY" ) && ( ref( $_[1] ) eq "ARRAY" )
        || confess "gjostat::contingency_chi_sqr_2:  requires two array references\n";

    my $ncol = @{ $_[0] };
    ( $ncol == @{ $_[1] } )
        || confess "gjostat::contingency_chi_sqr_2:  all rows must have same number of items\n";

    my ( @csum, @rsum );
    my $sum = 0;
    my $n;

    foreach my $row ( @_ )
    {
        my $rsum = 0;
        for (my $i = 0; $i < $ncol; $i++)
        {
            $n = $row->[ $i ];
            $rsum += $n;
            $csum[ $i ] += $n;
        }

        ( $rsum > 0 ) || return (0, 0, 0);
        push @rsum, $rsum;
        $sum += $rsum;
    }

    $ncol = 0;
    foreach ( @csum ) { $ncol++ if $_ > 0 }
    ( $ncol > 1 ) || return (0, 0, 0);

    my $chi_sqr = 0;
    my ( $e, $rsum, $c );
    foreach my $row ( @_ )
    {
        $rsum = shift @rsum;

        for (my $i = 0; $i < $ncol; $i++)
        {
            ( ( $c = $csum[ $i ] ) > 0 ) || next;
            $e = $rsum * $c / $sum;
            $chi_sqr += ( $row->[ $i ] - $e )**2 / $e;
        }
    }

    ( $chi_sqr, $ncol-1, $sum )
}


#-----------------------------------------------------------------------------
#   Probability of a chi square value greater than or equal to chisqr
#
#   Based on:
#
#   Zelen, M. and Severo, N. C. (1965).  Probability functions.  In
#   Handbook of Mathematical Functions, Abramowitz, M. and Stegun,
#   I. A., eds. (New York: Dover Publications), pp. 925-995.
#
#   Programmed in perl by Gary Olsen
#
#      $p_value = chisqr_prob( $chisqr, $df )
#-----------------------------------------------------------------------------

sub chisqr_prob
{
    my ($chisqr, $df) = @_;
    defined($chisqr) && defined($df)
              || confess "gjostat::chisqr_prob: undefined arguement\n";

    ($chisqr >= 0)  || confess "gjostat::chisqr_prob: bad chi square value: $chisqr\n";
    ($df > 0) && (int($df) == $df)
              || confess "gjostat::chisqr_prob: bad degrees of freedom: $df\n";

    if ($chisqr == 0) { return 1 }
    if ($chisqr - $df - 10*sqrt($df) > 49.0) { return 1e-14 }

    my $inverseProb = 1;
    my $delta = 1;
    my $denom = $df;

    while ( 1e16 * $delta > $inverseProb )
    {
        $denom += 2;
        $delta *= $chisqr / $denom;
        $inverseProb += $delta;
    }

    $denom = $df;
    my $i;
    for ($i = $df - 2; $i > 0; $i -= 2) { $denom *= $i }

    $inverseProb *= exp(-0.5 * $chisqr) * $chisqr**int(0.5*($df+1)) / $denom;

    # pi/2 = 1.57079632679489661923

    if ($df % 2 != 0) { $inverseProb /= sqrt(1.57079632679489661923 * $chisqr) }

    1 - $inverseProb;
}


#-----------------------------------------------------------------------------
#  Find the chi square value required for a given critical P-value:
#
#     $chisqr = chisqr_critical_value( $p_value, $df )
#-----------------------------------------------------------------------------

sub chisqr_critical_value
{
    ( 2 == @_ ) || confess "gjostat::chisqr_critical_value called without 2 args\n";
    my ($prob, $df) = @_;

    ( $prob > 1e-13 ) && ( $prob < 1 )
                      || confess "gjostat::chisqr_critical_value:  chi square out of range: $prob\n";

    ( $df > 0 ) && ( $df <= 200 )
                || confess "gjostat::chisqr_critical_value:  df out of range: $df\n";

    my $chisqr = $df + 3 * sqrt($df);
    my $step;

    if (chisqr_prob($chisqr, $df) > $prob)
    {
       $chisqr *= 2.0;
       while (chisqr_prob($chisqr, $df) > $prob) { $chisqr *= 2.0 }
       $step = 0.25 * $chisqr;
    }
    else
    {
       $step = 0.5 * $chisqr;
    }

    $chisqr -= $step;
    $step   *= 0.5;

    while ($step > 1e-9 * $chisqr)
    {
       if (chisqr_prob($chisqr, $df) > $prob) { $chisqr += $step }
       else                                   { $chisqr -= $step }
       $step *= 0.5;
    }

    $chisqr;
}


#  Binomial distribution probabilities: ======================================

#  $coef = binomial_coef($n, $m)

sub binomial_coef
{
    ( 2 == @_ ) || confess "gjostat::binomial_coef called without 2 args\n";
    my ($n, $m) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                || confess "gjostat::binomial_coef called with invalid arg values\n";
    ( 2 * $m <= $n ) ? binomial_coef_1( $n, $m )
                     : binomial_coef_1( $n, $n-$m );
}


#  $prob = binomial_prob_eq_m($n, $m, $p)

sub binomial_prob_eq_m
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_eq_m called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_eq_m called with invalid arg values\n";
    if ( $p == 0 ) { return ($m ==  0) ? 1 : 0 }
    if ( $p == 1 ) { return ($m == $n) ? 1 : 0 }

    #  If no underflow is predicted, to exact calc

    ( ( $n <= 1020 ) && ( $m * log($p) + ($n-$m) * log(1-$p) > -744 ) )
        ? binomial_coef_0($n, $m) * $p**$m * (1-$p)**($n-$m)
        : exp(ln_binomial_coef_0($n, $m) + $m*log($p) + ($n-$m)*log(1-$p));
}


sub binomial_prob_le_m
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_le_m called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_le_m called with invalid arg values\n";

    if ( ( $p == 0 ) || ( $m == $n ) ) { return 1 }
    if (   $p == 1 ) { return 0 }    # special case of m == n handled above

    #  Figure out the most accurate direction to come from

    my ($pn, $w);
    $pn = $p * $n;
    $w = 2 * sqrt($pn * (1-$p));
    ( ($m < $pn - $w) || ( (2 * $m <= $n) && ($m < $pn + $w) ) )
        ?      binomial_prob_le_m_00($n, $m,   $p)
        :  1 - binomial_prob_ge_m_00($n, $m+1, $p);
}


sub binomial_prob_ge_m
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_ge_m called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_ge_m called with invalid arg values\n";

    if ( ( $p == 1 ) || ( $m == 0 ) ) { return 1 }
    if (   $p == 0 ) { return 0 }        # special case of $m == 0 handled above

    #  Figure out the most accurate direction to come from

    my ($pn, $w);
    $pn = $p * $n;
    $w = 2 * sqrt($pn * (1-$p));
    ( ($m > $pn + $w) || ( (2 * $m >= $n) && ($m > $pn - $w) ) )
        ?      binomial_prob_ge_m_00($n, $m,   $p)
        :  1 - binomial_prob_le_m_00($n, $m-1, $p);
}


sub ln_binomial_coef
{
    ( 2 == @_ ) || confess "gjostat::ln_binomial_coef called without 2 args\n";
    my ($n, $m) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                || confess "gjostat::ln_binomial_coef called with invalid arg values\n";

    ( 2 * $m <= $n ) ? ln_binomial_coef_1($n, $m)
                     : ln_binomial_coef_1($n, $n-$m);
}


sub ln_binomial_prob_eq_m
{
    ( 3 == @_ ) || confess "gjostat::ln_binomial_prob_eq_m called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::ln_binomial_prob_eq_m called with invalid arg values\n";
    if ( $p == 0 ) { return ($m ==  0) ? 0 : undef }
    if ( $p == 1 ) { return ($m == $n) ? 0 : undef }

    ln_binomial_coef_0($n, $m) + $m*log($p) + ($n-$m)*log(1-$p);
}


# value of m such that P(>=m) <= P

sub binomial_critical_value_m_ge
{
    ( 3 == @_ ) || confess "gjostat::binomial_critical_value_m_ge called without 3 args\n";
    my ($n, $p, $P) = @_;
    ( $n >= 1 ) && ( $P >  0 )
                && ( $P <= 1 )
                && ( $p >= 0 )
                && ( $p <  1 )
                || confess "gjostat::binomial_critical_value_m_ge called with invalid arg values\n";
    if ( $P == 1 ) { return 0 }
    if ( $p == 0 ) { return 1 }

    my ($m, $P_ge_m, $term, $q_over_p);
    $P_ge_m = $term = binomial_prob_eq_m_00($n, $n, $p);
    if ( $P_ge_m > $P ) { return undef }

    $m = $n;
    $q_over_p = (1-$p) / $p;
    while ( --$m >= 1 )
    {
        if ($P_ge_m == $P) { return $m }
        $P_ge_m += $term *= (($m+1) / ($n-$m)) * $q_over_p;
        if ($P_ge_m > $P) { return $m+1 }
    }

    1;
}


sub binomial_critical_value_m_le
{
    ( 3 == @_ ) || confess "gjostat::binomial_critical_value_m_le called without 3 args\n";
    my ($n, $p, $P) = @_;
    ( $n >= 1 ) && ( $P >  0 )
                && ( $P <= 1 )
                && ( $p >  0 )
                && ( $p <= 1 )
                || confess "gjostat::binomial_critical_value_m_le called with invalid arg values\n";
    if ($P == 1) { return $n }
    if ($p == 1) { return $n-1 }

    my ($m, $P_le_m, $term, $p_over_q);
    $P_le_m = $term = binomial_prob_eq_m_00($n, 0, $p);
    if ($P_le_m > $P) { return undef }

    $m = 0;
    $p_over_q = $p / (1-$p);
    while (++$m < $n)
    {
        if ($P_le_m == $P) { return $m }
        $P_le_m += $term *= (($n-$m+1) / $m) * $p_over_q;
        if ($P_le_m > $P) { return $m-1 }
    }

    $n-1;
}


#  Binomial probability helper functions: ====================================


#  Given probability of i-1 out of n, what is probability of i out of n?

sub binomial_next_prob_00
{
    my ($n, $i, $p_over_q, $prob0) = @_;

    $prob0 * ( ($n-$i+1) / $i ) * $p_over_q;
}


#  Given probability of i+1 out of n, what is probability of i out of n?

sub binomial_prev_prob_00
{
    my ($n, $i, $p_over_q, $prob0) = @_;

    $prob0 * ( ($i+1) / ($n-$i) ) / $p_over_q;
}


#  Some basic functions:  ====================================================

sub binomial_coef_0 {                   # no error checking
    my ($n, $m) = @_;
    ( 2 * $m <= $n ) ? binomial_coef_1($n, $m)
                     : binomial_coef_1($n, $n-$m);
}


sub binomial_coef_1
{
    my ($n, $m) = @_;
    my $c = 1;
    while ($m > 0) { $c *= $n-- / $m-- }
    int($c + 0.5);
}


sub binomial_prob_eq_m_0 {            # no error checking
    my ($n, $m, $p) = @_;
    if ($p == 0) { return ($m ==  0) ? 1 : 0 }
    if ($p == 1) { return ($m == $n) ? 1 : 0 }
    (($n <= 1020) && ($m*log($p) + ($n-$m)*log(1-$p) > -744))
        ? binomial_coef_0($n, $m) * $p**$m * (1-$p)**($n-$m)
        : exp(ln_binomial_coef_0($n, $m) + $m*log($p) + ($n-$m)*log(1-$p));
}


#  Logarithm-based versions for large n:  ====================================

sub ln_binomial_coef_0 {                 # no error checking
    my ($n, $m) = @_;
    ( 2 * $m <= $n ) ? ln_binomial_coef_1($n, $m)
                     : ln_binomial_coef_1($n, $n-$m);
}


sub ln_binomial_coef_1
{
    my ($n, $m) = @_;
    my $c = 0;
    while ($m > 0) { $c += log($n-- / $m--) }
    $c;
}


sub ln_binomial_prob_eq_m_0 {         # no error checking
    my ($n, $m, $p) = @_;
    if ($p == 0) { return ($m ==  0) ? 1 : 0 }
    if ($p == 1) { return ($m == $n) ? 1 : 0 }
    ln_binomial_coef_0($n, $m) + $m*log($p) + ($n-$m)*log(1-$p);
}


#  version for large n?
#
# function binomial_prob_eq_m_x_0(n, m, p) {          # no error checking
#     if (p == 0) return (m == 0) ? 1 : 0;
#     if (p == 1) return (m == n) ? 1 : 0;
#     if (m <= 0.5 * n) return  binomial_prob_eq_m_x_1(n, m, p);
#     else              return  binomial_prob_eq_m_x_1(n, n-m, 1-p);
#     }
#
# function binomial_prob_eq_m_x_1(n, m, p,    c, f) { # m <= n/2
#     if (m == 0) return  (1-p)^n;
#     f = p * (1-p)^((n-m)/m);
#     c = 1;
#     while (m > 0) c *= f * n-- / m--;
#     return  c;
#     }


sub binomial_prob_eq_m_00 {      # no checking; no special cases
    my ($n, $m, $p) = @_;
    ( ($n <= 1020) && ($m*log($p) + ($n-$m)*log(1-$p) > -744) )
        ?  binomial_coef_0($n, $m) * $p**$m * (1-$p)**($n-$m)
        :  exp(ln_binomial_coef_0($n, $m) + $m*log($p) + ($n-$m)*log(1-$p));
}


sub binomial_prob_le_m_00
{
    my ($n, $m, $p) = @_;
    my ($prob, $term, $q_over_p);

    $prob = $term = binomial_prob_eq_m_00($n, $m, $p);
    $q_over_p = (1-$p) / $p;
    while (--$m >= 0 && (1e16 * $term > $prob))
    {
        $prob += $term *= (($m+1) / ($n-$m)) * $q_over_p;
    }

    $prob;

#   prob = term = (1-p)^n;
#   p_over_q = p / (1-p);
#   for (i = 1; i <= m; i++) prob += term *= ((n-i+1) / i) * p_over_q;
#   return  prob;
}


sub binomial_prob_ge_m_00
{
    my ($n, $m, $p) = @_;
    my ($prob, $term, $p_over_q);

    $prob = $term = binomial_prob_eq_m_00($n, $m, $p);
    $p_over_q = $p / (1-$p);
    while (++$m <= $n && (1e16 * $term > $prob))
    {
        $prob += $term *= (($n-$m+1) / $m) * $p_over_q;
    }

    $prob;

#   prob = term = p^n;
#   q_over_p = (1-p) / p;
#   for (i = n-1; i >= m; i--) prob += term *= ((i+1) / (n-i)) * q_over_p;
#   return  prob;
}


#  Binomial probability slower cleaner versions for checking results: ========


#  $P = binomial_prob_le_m_slower( $n, $m, $p )

sub binomial_prob_le_m_slower
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_le_m_slower called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_lbinomial_prob_le_m_slowere_m called with invalid arg values\n";

    if ( ( $p == 0 ) || ( $m == $n ) ) { return 1 }
    if (   $p == 1 ) { return 0 }    # special case of m == n handled above

    my ($prob, $term, $p_over_q, $i);
    $prob = $term = (1-$p)**$n;
    $p_over_q = $p / (1-$p);
    for ($i = 1; $i <= $m; $i++)
    {
        $prob += $term = binomial_next_prob_00($n, $i, $p_over_q, $term);
    }

    $prob;
}


#  $P = binomial_prob_ge_m_slower( $n, $m, $p )

sub binomial_prob_ge_m_slower
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_ge_m_slower called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_ge_m_slower called with invalid arg values\n";

    if ( ( $p == 1 ) || ( $m == 0 ) ) { return 1 }
    if (   $p == 0 ) { return 0 }        # special case of $m == 0 handled above

    my ($prob, $term, $p_over_q, $i);
    $prob = $term = $p**$n;
    $p_over_q = $p / (1-$p);
    for ($i = $n-1; $i >= $m; $i--)
    {
        $prob += $term = binomial_prev_prob_00($n, $i, $p_over_q, $term);
    }

    $prob;
}


#  $P = binomial_prob_le_m_slowest( $n, $m, $p )

sub binomial_prob_le_m_slowest
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_le_m_slowest called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_le_m_slowest called with invalid arg values\n";

    if ( ( $p == 0 ) || ( $m == $n ) ) { return 1 }
    if (   $p == 1 ) { return 0 }    # special case of m == n handled above

    my ($prob, $i);
    $prob = (1-$p)**$n;
    for ($i = 1; $i <= $m; $i++) { $prob += binomial_prob_eq_m_00($n, $i, $p) }

    $prob;
}


#  $P = binomial_prob_ge_m_slowest( $n, $m, $p )

sub binomial_prob_ge_m_slowest
{
    ( 3 == @_ ) || confess "gjostat::binomial_prob_ge_m_slowest called without 3 args\n";
    my ($n, $m, $p) = @_;
    ( $n >= 1 ) && ( $m >=  0 )
                && ( $m <= $n )
                && ( $p >=  0 )
                && ( $p <=  1 )
                || confess "gjostat::binomial_prob_ge_m_slowest called with invalid arg values\n";

    if ( ( $p == 1 ) || ( $m == 0 ) ) { return 1 }
    if (   $p == 0 ) { return 0 }        # special case of $m == 0 handled above

    my ($prob, $i);
    $prob = $p**$n;
    for ($i = $n-$1; $i >= $m; $i--) { $prob += binomial_prob_eq_m_00($n, $i, $p) }

    $prob;
}


#  Probability under standard normal curve  ==================================

#  $P = std_normal_le_z( $z )

sub std_normal_le_z
{
    ( 1 == @_ ) || confess "gjostat::std_normal_le_z called without 1 arg\n";
    my ($z) = @_;
    ($z <= 0) ?     std_normal_le_z_1( $z)
              : 1 - std_normal_le_z_1(-$z);
}


#  $P = std_normal_ge_z( $z )

sub std_normal_ge_z
{
    ( 1 == @_ ) || confess "gjostat::std_normal_ge_z called without 1 arg\n";
    my ($z) = @_;
    ($z >= 0) ?     std_normal_le_z_1(-$z)
              : 1 - std_normal_le_z_1( $z);
}

#  $P std_normal_le_z_1( $z )  # -38.4 <= z <= 0

#  pi / 2           = 1.57079632679489661923
#  sqrt(2 / pi)     = 0.797884560802865
#  sqrt(2 / pi) / 6 = 0.13298076013381091

sub  std_normal_le_z_1
{
    my $step = 0.003;
    my ($z) = @_;
    if ( $z < -38.4 ) { return 0 }
    my ($y, $y2, $p);
    $p = 0;
    $y = exp(-0.5 * $z * $z);
    while ( ( $z >= -38.4 ) && ( 1e15 * $y > $p ) )
    {
        $z -= $step;
        $y += 4 * exp(-0.5 * $z * $z);
        $z -= $step;
        $p += $y + ( $y2 = exp(-0.5 * $z * $z) );
        $y  = $y2;
    }

    0.13298076013381091 * $p * $step;
}


#  $z = std_normal_critical_value_z_ge( $P )

sub std_normal_critical_value_z_ge
{
    ( 1 == @_ ) || confess "gjostat::std_normal_critical_value_z_ge called without 1 arg\n";
    my ($P) = @_;
    ( $P > 0 ) && ( $P < 1 )
               ||  confess "gjostat::std_normal_critical_value_z_ge argument out of range\n";
    ( $P <= 0.5 ) ?  std_normal_critical_value_z_ge_2(     $P )
                  : -std_normal_critical_value_z_ge_2( 1 - $P )
}


#  $z = std_normal_critical_value_z_le( $P )

sub std_normal_critical_value_z_le
{
    ( 1 == @_ ) || confess "gjostat::std_normal_critical_value_z_le called without 1 arg\n";
    my ($P) = @_;
    ( $P > 0 ) && ( $P < 1 )
               ||  confess "gjostat::std_normal_critical_value_z_le argument out of range\n";

    ( $P <= 0.5 ) ? -std_normal_critical_value_z_ge_2(     $P )
                  :  std_normal_critical_value_z_ge_2( 1 - $P )
}


#  $Z = std_normal_critical_value_z_ge_2 ( $P )   # 0 < P <= 0.5
#
#  Good to 8 or more significant figures in Z
#  (not sure why it does not get even better)

sub std_normal_critical_value_z_ge_2
{
    my ($P) = @_;
    my $P0 = $P / 0.797884560802865;  # = sqrt(2 / pi)

    #  Get a quick estimate using large integration step from infinity

    my ($step, $step6, $z, $y0, $y1, $y2, $p, $p0);

    $step  = 0.025;
    $step6 = $step / 6;
    $z     = 38.6;
    $p     = 0;
    $y2    = exp(-0.5 * $z * $z);

    while ( $p < $P0 )
    {
        $p0 = $p;
        $y0 = $y2;
        $z -= $step;
        $y1 = exp(-0.5 * $z * $z);
        $z -= $step;
        $y2 = exp(-0.5 * $z * $z);
        $p += ( $y0 + 4 * $y1 + $y2 ) * $step6;
    }
    $z += 2 * $step;
    # printf STDERR "; z1 = %11.8f", $z;

    #  Coefs of x**3, x**2 and x**1 in integral of curve from z to z-prime

    my $c2 = ( 0.5 * ( $y2 + $y0 ) - $y1 ) / 3;
    my $c1 = $y1 - 0.25 * ( $y2 + 3 * $y0 );
    my $c0 = $y0;

    my $dp;

    my $frac = 1;
    my $fracstep = $frac;
    my $step2 = 0.5 * $step;

    while ( $fracstep > 0.00001 )
    {
        $dp = ( ( (  $c2 * $frac ) + $c1 ) * $frac + $c0 ) * $frac * $step2;
        $fracstep *= 0.5;
        if ( $p0 + $dp > $P0 ) { $frac -= $fracstep }
        else                   { $frac += $fracstep }
    }
    my $z0 = $z - $frac * $step;
    # printf STDERR "; z2 = %11.8f", $z0;

    #  Find out how much we missed P by

    my $dp0 = ( $P - std_normal_le_z_1(-$z0) ) / 0.797884560802865;
    if ( $dp0 == 0 ) { return $z0 }

    #  Figure out how far to move to fix the value of the integral

    $y0 = exp(-0.5 * $z0 * $z0);
    $step = 2 * $dp0 / $y0;            # linear approximation
    # printf STDERR "; step = %11.8f", $step;

    my $z1 = $z0 + $step;
    my $z2 = $z1 + $step;
    $y1 = exp(-0.5 * $z1 * $z1);
    $y2 = exp(-0.5 * $z2 * $z2);

    #  Coefs of x**3, x**2 and x**1 in integral of curve from z to z-prime

    $c2 = ( 0.5 * ( $y2 + $y0 ) - $y1 ) / 3;
    $c1 = $y1 - 0.25 * ( $y2 + 3 * $y0 );
    $c0 = $y0;

    $frac = 1;
    $fracstep = $frac;
    $step2 = 0.5 * abs($step);
    $dp0 = abs($dp0);

    while ( $fracstep > 0.00001 )
    {
        $dp = ( ( (  $c2 * $frac ) + $c1 ) * $frac + $c0) * $frac * $step2;
        $fracstep *= 0.5;
        if ( $dp > $dp0 ) { $frac -= $fracstep }
        else              { $frac += $fracstep }
    }

    $z0 - $frac * $step;
}


# $z = std_normal_critical_value_z_ge_1($P)  # 0 < P < 0.5
#
# Earlier, slower version of critical z-value calculation.
# Currently not used.

sub std_normal_critical_value_z_ge_1
{
    my ($P) = @_;
    $P /= 0.13298076013381091;   # = sqrt(2 / pi) / 6

    my $step = 0.01;
    my $z = 38.6;
    my ($y, $p, $p0);
    $p = 0;
    $y = exp(-0.5 * $z * $z) * $step;
    while ( $p < $P )
    {
        $p0 = $p;
        $z -= $step;
        $p += $y + 4 * exp(-0.5 * $z * $z) * $step;
        $z -= $step;
        $p += ($y = exp(-0.5 * $z * $z) * $step);
    }

    $z += 2 * $step;
    my $y0 = exp(-0.5 * $z * $z);
    my $stepstep = $step *= 0.5;

    while ( $stepstep > 1e-10 )
    {
       $y = $step * (     $y0
                    + 4 * exp(-0.5 * ($z -   $step) * ($z -   $step))
                    +     exp(-0.5 * ($z - 2*$step) * ($z - 2*$step))
                    );
       $stepstep *= 0.5;
       if ( $p0 + $y > $P ) { $step -= $stepstep }
       else                 { $step += $stepstep }
   }

   $z - 2*$step;
}



#  Poisson distribution probabilities  =======================================
#  none of these include check for integer arguments

sub  poisson_prob_eq_n
{
    ( 2 == @_ ) || confess "gjostat::poisson_prob_eq_n called without 2 args\n";
    my ($n, $mu) = @_;
    ( $n >= 0 ) && ( $mu >= 0 )
                || confess "gjostat::poisson_prob_eq_n called with invalid arg values\n";

    #  Figure out the most effective approach

    ( $mu == 0) ? ( ( $n == 0 ) ? 1 : 0 )
                : poisson_prob_eq_n_0($n, $mu);
}


sub  poisson_prob_le_n
{
    ( 2 == @_ ) || confess "gjostat::poisson_prob_le_n called without 2 args\n";
    my ($n, $mu) = @_;
    ( $n >= 0 ) && ( $mu >= 0 )
                || confess "gjostat::poisson_prob_le_n called with invalid arg values\n";

    #  Figure out the most effective approach

      ( $mu == 0 )                   ? 1
    : ( $n  == 0 )                   ? exp(-$mu)
    : ( $n  <= $mu + 5 * sqrt($mu) ) ? poisson_prob_le_n_0($n, $mu)
    :                                  1 - poisson_prob_ge_n_0($n+1, $mu);
}


sub  poisson_prob_ge_n
{
    ( 2 == @_ ) || confess "gjostat::poisson_prob_ge_n called without 2 args\n";
    my ($n, $mu) = @_;
    ( $n >= 0 ) && ( $mu >= 0 )
                || confess "gjostat::poisson_prob_ge_n called with invalid arg values\n";

    #  Figure out the most effective approach

      ( $n  == 0 )                   ? 1
    : ( $mu == 0 )                   ? 0       #  n == 0 handled above
    : ( $n  >= $mu + 5 * sqrt($mu) ) ? poisson_prob_ge_n_0($n, $mu)
    :                                  1 - poisson_prob_le_n_0($n-1, $mu);
}


sub  poisson_prob_le_n_0
{
    my ($n, $mu) = @_;
    my ($p, $term);
    $p = $term = poisson_prob_eq_n_0($n, $mu);
    while ( ( --$n >= 0) && ( 1e16 * $term > $p ) )
    {
        $p += ( $term *= ($n+1) / $mu );
    }

    $p;
}


sub  poisson_prob_ge_n_0
{
    my ($n, $mu) = @_;
    my ($p, $term);
    $p = $term = poisson_prob_eq_n_0($n, $mu);
    while ( 1e16 * $term > $p ) { $p += ( $term *= $mu / (++$n) ) }

    $p;
}


sub  poisson_prob_eq_n_0
{
    my ($n, $mu) = @_;
    if ( $n <= 120 ) { return  $mu**$n * exp(-$mu) / factorial_0($n) }

    my $ln_p = $n * log($mu) - $mu - ln_factorial_0($n);
    ($ln_p > -744) ? exp($ln_p) : 0;
}


sub  factorial
{
    ( 1 == @_ ) || confess "gjostat::factorial called without 1 arg\n";
    my $n = shift;
    ( $n >= 0 ) && ( $n <= 170)
                || confess "gjostat::factorial called with out of range argument: '$n'\n";

    factorial_0( $n );
}


{
my @factorial = (1,1);
sub  factorial_0
{
    my $n = shift;
    return $factorial[$n] if @factorial > $n;

    my $i = @factorial;
    my $f = $factorial[$i-1];
    $factorial[$n] = undef;
    while ( $i <= $n ) { $factorial[$i] = $f *= $i++ }
    $f;
}
}


sub  ln_factorial
{
    ( 1 == @_ ) || confess "gjostat::ln_factorial called without 1 arg\n";
    my $n = shift;
    ( $n >= 0 ) && ( $n <= 1e7)
                || confess "gjostat::ln_factorial called with out of range argument\n";

    ln_factorial_0( $n );
}


{
my @ln_factorial = (0,0);
sub  ln_factorial_0
{
    my $n = shift;
    return $ln_factorial[$n] if @ln_factorial > $n;

    my $i = @ln_factorial;
    my $f = $ln_factorial[$i-1];
    $ln_factorial[$n] = undef;
    while ( $i <= $n ) { $ln_factorial[$i] = $f += log($i++) }
    $f;
}
}

#  Given probability of i-1, what is probability of i?

sub  poisson_next_prob
{
    my ($i, $mu, $prob0) = @_;
    ( $i > 0 ) ? $prob0 * $mu / $i : undef;
}


#  Given probability of i+1, what is probability of i?

sub  poisson_prev_prob
{
    my ($i, $mu, $prob0) = @_;
    ( $i >= 0 ) ? $prob0 * ($i+1) / $mu : undef;
}


1;
