
use Test::More tests => 20;

use warnings;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;


$strf = DateTime::Format::Duration->new(
    base => DateTime->new(year=>2003),
    pattern => '%V weeks, %u days',
);
$duration = DateTime::Duration->new( days => 17 );
is( $strf->format_duration( $duration ), '2 weeks, 3 days', '17 days = 2 weeks, 3 days' );




$strf = DateTime::Format::Duration->new(
    pattern => '%N %6N %3N',
);
$duration = DateTime::Duration->new( days => 17, nanoseconds => 654321987 );
is( $strf->format_duration( $duration ), '654321987 654321 654', 'Nanosecond precision' );




$strf = DateTime::Format::Duration->new(
    pattern => '%V',
    base    => DateTime->new( year => 2003 ),
);
$duration = DateTime::Duration->new( days => 22, hours => 36 );
is( $strf->format_duration( $duration ), '3', '22 days, 36 hours as integer weeks' );

$strf->set_pattern('%W');
is( $strf->format_duration( $duration ), '3.357142857', '22 days, 36 hours as floating weeks' );

$strf->set_pattern('%j');
is( $strf->format_duration( $duration ), '23', '22 days, 36 hours as days' );

$strf->set_pattern('%s');
is( $strf->format_duration( $duration ), (22*24*60*60) + (36*60*60), '22 days, 36 hours as seconds' );

$strf->set_pattern('%u');
is( $strf->format_duration( $duration ), '2', '22 days, 36 hours as days modulus 7' );


$duration = DateTime::Duration->new( months => 2, days => 2, hours => 30, minutes => 3 );
$strf->set_normalising(1);
$strf->set_pattern('%H');
is( $strf->format_duration( $duration ), '06','format %H 30 - 24 = 06' );

$strf->set_pattern('%-H');
is( $strf->format_duration( $duration ), '6','format %-H 30 - 24 = 6' );

$strf->set_pattern('%I');
is( $strf->format_duration( $duration ), '06','format %I 30 - 24 = 06' );

$strf->set_pattern('%-I');
is( $strf->format_duration( $duration ), '6','format %-I 30 - 24 = 6' );

$strf->set_pattern('%k');
is( $strf->format_duration( $duration ), ' 6','format %k 30 - 24 =  6' );

$strf->set_pattern('%-k');
is( $strf->format_duration( $duration ), '6','format %-k 30 - 24 = 6' );

$strf->set_pattern('%l');
is( $strf->format_duration( $duration ), ' 6','format %l 30 - 24 =  6' );

$strf->set_pattern('%-l');
is( $strf->format_duration( $duration ), '6','format %-l 30 - 24 = 6' );

$strf->set_pattern('%e');
is( $strf->format_duration( $duration ), '3','format %e 3 days' );

$strf->set_pattern('%m');
is( $strf->format_duration( $duration ), '02','format %m 02 months' );

$strf->set_pattern('%-m');
is( $strf->format_duration( $duration ), '2','format %-m 2 months' );

$strf->set_pattern('%M');
is( $strf->format_duration( $duration ), '03','format %M 03 minutes' );

$strf->set_pattern('%-M');
is( $strf->format_duration( $duration ), '3','format %-M 3 minutes' );

