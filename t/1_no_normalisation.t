use Test::More tests => 14;

use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;



$strf = DateTime::Format::Duration->new(
	normalise => 0,
	pattern => '%F %r',
);


$duration = DateTime::Duration->new( seconds => 59 );
is( $strf->format_duration( $duration ), '0000-00-00 00:00:59', 'No normalisation needed' );

$duration = DateTime::Duration->new( seconds => 60 );
is( $strf->format_duration( $duration ), '0000-00-00 00:00:60', 'Minimal normalisation' );

$duration = DateTime::Duration->new( seconds => 61 );
is( $strf->format_duration( $duration ), '0000-00-00 00:00:61', 'Normalised Value' );

$duration = DateTime::Duration->new( seconds => 60*60 );
is( $strf->format_duration( $duration ), '0000-00-00 00:00:3600', '3600 secs = 1 hour' );

$duration = DateTime::Duration->new( seconds => 60*60*24 );
is( $strf->format_duration( $duration ), '0000-00-00 00:00:86400', (60*60*24).' secs = 1 day' );

$duration = DateTime::Duration->new( days => 45 );
is( $strf->format_duration( $duration ), '0000-00-45 00:00:00', '45 days = 45 days' );

$duration = DateTime::Duration->new( months => 10000, days => 10000 );
is( $strf->format_duration( $duration ), '0000-10000-10000 00:00:00', 'Large values with no normalisation' );



$strf = DateTime::Format::Duration->new(
	base => DateTime->new(year=>2003),
	pattern => '%F %r',
);


$duration = DateTime::Duration->new( seconds => 59 );
is( $strf->format_duration( $duration ), '0000-00-00 00:00:59', 'No normalisation needed' );

$duration = DateTime::Duration->new( seconds => 60 );
is( $strf->format_duration( $duration ), '0000-00-00 00:01:00', 'Minimal normalisation' );

$duration = DateTime::Duration->new( seconds => 61 );
is( $strf->format_duration( $duration ), '0000-00-00 00:01:01', 'Normalised Value' );

$duration = DateTime::Duration->new( seconds => 60*60 );
is( $strf->format_duration( $duration ), '0000-00-00 01:00:00', '3600 secs = 1 hour' );

$duration = DateTime::Duration->new( seconds => 60*60*24 );
is( $strf->format_duration( $duration ), '0000-00-01 00:00:00', (60*60*24).' secs = 1 day' );

$duration = DateTime::Duration->new( days => 45 );
is( $strf->format_duration( $duration ), '0000-01-14 00:00:00', '45 days = 1 month, 14 days' );

$duration = DateTime::Duration->new( years => 10000, days => 10000 );
is( $strf->format_duration( $duration ), '10027-04-18 00:00:00', 'Large values with base' );






