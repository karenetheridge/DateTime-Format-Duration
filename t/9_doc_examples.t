use Test::More tests => 9;

use warnings;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;
use Data::Dumper;

my $d = DateTime::Format::Duration->new(
          pattern =>  '%Y years, %-m months, %e days, '.
                      '%-H hours, %M minutes, %S seconds',
          normalise => 1
        );

is($d->format_duration(
        DateTime::Duration->new(
          years   => 3,
          months  => 5,
          days    => 1,
          hours   => 6,
          minutes => 15,
          seconds => 45,
          nanoseconds => 12000
        )
      ),'3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds','First full format');

  # Returns DateTime::Duration object
my $duration = $d->parse_duration(
                    '3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds'
                );

is($d->format_duration_from_deltas(
        years   => 3,
        months  => 5,
        days    => 1,
        hours   => 6,
        minutes => 15,
        seconds => 45,
        nanoseconds => 12000
      ),'3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds',
  'From deltas');

my %deltas = $d->parse_duration_as_deltas(
                  '3 years, 5 months, 1 days, 6 hours, 15 minutes, 45 seconds'
                );

is($deltas{years},3,'3 years');
is($deltas{months},5,'5 months');
is($deltas{days},1,'1 days');
is($deltas{hours},6,'6 hours');
is($deltas{minutes},15,'15 minutes');
is($deltas{seconds},45,'45 seconds');
is($deltas{nanoseconds},0,'0 nanoseconds');

