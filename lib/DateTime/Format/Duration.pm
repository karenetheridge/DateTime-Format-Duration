package DateTime::Format::Duration;

use strict;
use Params::Validate qw( validate SCALAR OBJECT );
use constant MAX_NANOSECONDS => 1000000000;  # 1E9 = almost 32 bits

our $VERSION = '1.00';

sub new {
	my $class = shift;
	my %args = validate( @_, {
		pattern		=> { type => SCALAR },
		base		=> { type => OBJECT, default => undef },
		normalise	=> { type => SCALAR, default => 0 },
	});
	$args{normalise} = 1 if $args{base};
	
	return bless \%args, $class;
}

sub base {
	my $self = shift;
	my $newbase = shift;
	if ($newbase) {
		die "Argument to base() must be a DateTime object." unless ref($newbase) eq 'DateTime';
		$self->{base} = $newbase;
	}
	$self->{base};
}
sub pattern {
	my $self = shift;
	my $newpattern = shift;
	if ($newpattern) {
		$self->{pattern} = $newpattern;
		$self->{parser} = '';
	}
	$self->{pattern};
}
sub normalising {
	my $self = shift;
	my $new = shift;
	if ($new) {
		$self->{normalise} = $new;
	}
	($self->{normalise}) ? 1 : 0;
}

sub normalise {
	my $self = shift;
	
	my %delta = (ref($_[0]) =~/^DateTime::Duration/)
		? $_[0]->deltas
		: @_;
		
	return %delta unless $self->{normalise};
	
	if ($self->{diagnostic}) {require Data::Dumper; print 'Pre Underflow: ' . Data::Dumper::Dumper( \%delta );}	
	
	while ($delta{nanoseconds} < 0) {
		$delta{nanoseconds} += MAX_NANOSECONDS;
		$delta{seconds} -= 1;
	}

	while ($delta{seconds} < 0) {
		$delta{seconds} += 60;
		$delta{minutes} -= 1;
	}

	while ($delta{minutes} < 0) {
		$delta{minutes} += 60;
		$delta{hours} -= 1;
	}

	while ($delta{hours} < 0) {
		$delta{hours} += 24;
		$delta{days} -= 1;
	}

	while ($delta{days} < 0 and defined $self->{base}) {
		$delta{days} += DateTime->last_day_of_month( year => $self->{base}->year, month => $self->{base}->month )->day;
		$delta{months} -= 1;
	}

	while ($delta{months} < 0) {
		$delta{months} += 12;
		$delta{years} -= 1;
	}
	
	if ($self->{diagnostic}) {require Data::Dumper; print 'Pre Denegation: ' . Data::Dumper::Dumper( \%delta );}	
	
	if ($delta{years} < 0) {
		# It's a negative value .. so we need to turn all values into negatives
		$delta{months} -= 12;
		$delta{years} += 1;
		if ($delta{months} < 0 and defined($self->{base})) {
			$delta{days} -= DateTime->last_day_of_month( year => $self->{base}->year, month => $self->{base}->month )->day;          
			$delta{months} += 1
		}
		if ($delta{days} < 0) {
			$delta{hours} -= 24;          
			$delta{days} += 1
		}
		if ($delta{hours} < 0) {
			$delta{minutes} -= 60;          
			$delta{hours} += 1
		}
		if ($delta{minutes} < 0) {
			$delta{seconds} -= 60;          
			$delta{minutes} += 1
		}
		if ($delta{seconds} < 0) {
			$delta{nanoseconds} -= MAX_NANOSECONDS;          
			$delta{seconds} += 1
		}
		
	}
	
	if ($self->{diagnostic}) {require Data::Dumper; print 'Pre Overflow: ' . Data::Dumper::Dumper( \%delta );}	
	
	# Now fix overflows and underflows
	while ($delta{nanoseconds} >= MAX_NANOSECONDS) {
		$delta{nanoseconds} -= MAX_NANOSECONDS;
		$delta{seconds} += 1;
	}
	while ($delta{nanoseconds} <= -&MAX_NANOSECONDS()) {
		$delta{nanoseconds} += MAX_NANOSECONDS;
		$delta{seconds} -= 1;
	}

	while ($delta{seconds} >= 60) {
		$delta{seconds} -= 60;
		$delta{minutes} += 1;
	}
	while ($delta{seconds} <= -60) {
		$delta{seconds} += 60;
		$delta{minutes} -= 1;
	}

	while ($delta{minutes} >= 60) {
		$delta{minutes} -= 60;
		$delta{hours} += 1;
	}
	while ($delta{minutes} <= -60) {
		$delta{minutes} += 60;
		$delta{hours} -= 1;
	}

	while ($delta{hours} >= 24) {
		$delta{hours} -= 24;
		$delta{days} += 1;
	}
	while ($delta{hours} <= -24) {
		$delta{hours} += 24;
		$delta{days} -= 1;
	}

	if (defined $self->{base}) {
		my $reference = DateTime->last_day_of_month( year => $self->{base}->year, month => $self->{base}->month );
		$reference = $reference->add( months => $delta{months}, end_of_month=>'preserve');
		my $days_in_month = $reference->day;
		while ($delta{days} >= $days_in_month) {
			$delta{days} -= $days_in_month;
			$delta{months} += 1;
			$reference = $reference->add( months => 1, end_of_month=>'preserve');
			$days_in_month = $reference->day;
		}
		while ($delta{days} <= -$days_in_month) {
			$delta{days} += $days_in_month;
			$delta{months} -= 1;
			$reference = $reference->add( months => -1, end_of_month=>'preserve');
			$days_in_month = $reference->day;
		}
	}
	
	while ($delta{months} >= 12) {
		$delta{months} -= 12;
		$delta{years} += 1;
	}
	while ($delta{months} <= -12) {
		$delta{months} += 12;
		$delta{years} -= 1;
	}
	
		
	if ($self->{diagnostic}) {require Data::Dumper; print 'Post Norm: ' . Data::Dumper::Dumper( \%delta );}	
	
	foreach(qw/years months days hours minutes seconds nanoseconds/) {
		if ($delta{$_} < 0) {
			$delta{negative} = 1;
			$delta{$_} *= -1 
		}
	}
	
	if ($self->{diagnostic}) {require Data::Dumper; print 'Post Abs: ' . Data::Dumper::Dumper( \%delta );}	
	return %delta;
}
*normalize = \&normalise;
*normalize = \&normalise;

my %formats =
    ( 'C' => sub { int( $_[0]->{years} / 100 ) },
      'd' => sub { sprintf( '%02d', $_[0]->{days} ) },
      'e' => sub { sprintf( '%d', $_[0]->{days} ) },
      'F' => sub { sprintf( '%04d-%02d-%02d', $_[0]->{years}, $_[0]->{months}, $_[0]->{days} ) },
      'H' => sub { sprintf( '%02d', $_[0]->{hours} ) },
      'I' => sub { sprintf( '%02d', $_[0]->{hours} ) },
      'j' => sub { $_[1]->as_days($_[0]) },
      'k' => sub { sprintf( '%2d', $_[0]->{hours} ) },
      'l' => sub { sprintf( '%2d', $_[0]->{hours} ) },
      'm' => sub { sprintf( '%02d', $_[0]->{months} ) },
      'M' => sub { sprintf( '%02d', $_[0]->{minutes} ) },
      'n' => sub { "\n" }, # should this be OS-sensitive?"
      'N' => sub { _format_nanosecs(@_) },
	  'p' => sub { ($_[0]->{negative}) ? '-' : '+' },
	  'P' => sub { ($_[0]->{negative}) ? '-' : '' },
      'r' => sub { sprintf('%02d:%02d:%02d', $_[0]->{hours}, $_[0]->{minutes}, $_[0]->{seconds} ) },
      'R' => sub { sprintf('%02d:%02d', $_[0]->{hours}, $_[0]->{minutes}) },
      's' => sub { $_[1]->as_seconds($_[0]) },
      'S' => sub { sprintf( '%02d', $_[0]->{seconds} ) },
      't' => sub { "\t" }, #"
      'T' => sub { sprintf('%s%02d:%02d:%02d', ($_[0]->{negative}) ? '-' : '', $_[0]->{hours}, $_[0]->{minutes}, $_[0]->{seconds} ) },
      'u' => sub { $_[1]->as_days($_[0]) % 7 },
	  'V' => sub { $_[1]->as_weeks($_[0]) },
      'W' => sub { int(($_[1]->as_seconds($_[0]) / (60*60*24*7))*1_000_000_000) / 1_000_000_000 },
      'y' => sub { sprintf( '%02d', substr( $_[0]->{years}, -2 ) ) },
      'Y' => sub { return $_[0]->{years} },
      '%' => sub { '%' },
    );

sub format_duration {
    my $self = shift;
    
	my $duration = shift;
	
	die("Argument to format_duration must be a DateTime::Duration object. Called from ".join(' ',caller())) unless ref($duration) =~/^DateTime::Duration/;

	my %duration = $self->normalise( $duration );
	
	my @formats = @_ || ($self->pattern);
	
	
    my @r;
    foreach my $f (@formats)
    {
        $f =~ s/
                %{(\w+)}
               /
                $duration->$1() if $duration->can($1);
               /sgex;

        # regex from Date::Format - thanks Graham!
       $f =~ s/
                %(\d*)([%a-zA-MO-Z]) # N returns from the left rather than the right
               /
                $formats{$2} 
					? ($1)
						? sprintf("%0$1d", substr($formats{$2}->(\%duration, $self),$1*-1) ) 
						: $formats{$2}->(\%duration, $self)
					: $1
					
               /sgex;

        # %3N
        $f =~ s/
                %(\d*)N
               /
                $formats{N}->(\%duration, $1)
               /sgex;

        return $f unless wantarray;

        push @r, $f;
    }

    return @r;
}


sub format_duration_from_deltas {
    my $self = shift;
    
	my %duration = $self->normalise( @_ );
	
	my @formats = $self->pattern;
	
	
    my @r;
    foreach my $f (@formats)
    {
	   # regex from Date::Format - thanks Graham!
       $f =~ s/
                %(\d*)([%a-zA-MO-Z]) # N returns from the left rather than the right
               /
                $formats{$2} 
					? ($1)
						? sprintf("%0$1d", substr($formats{$2}->(\%duration, $self),$1*-1) ) 
						: $formats{$2}->(\%duration, $self)
					: $1
					
               /sgex;

        # %3N
        $f =~ s/
                %(\d*)N
               /
                $formats{N}->(\%duration, $1)
               /sgex;

        return $f unless wantarray;

        push @r, $f;
    }

    return @r;
}


sub parse_duration {
	my $self = shift;
	DateTime::Duration->new(
		$self->parse_duration_as_deltas(@_)
	);
}

sub parse_duration_as_deltas {
    my ( $self, $time_string ) = @_;
	
	@{$self->{caller}} = caller;
	
	local $^W = undef;

	# Variables from the parser
	my (	$centuries,		$years,			$months,
			$weeks,			$days,			$hours,
			$minutes,		$seconds,		$nanoseconds
		);
			
	# Variables for DateTime
	my (	$Years,			$Months,		$Days,
			$Hours,			$Minutes,		$Seconds,		$Nanoseconds,
		) = ();
	
	# Run the parser
	my $parser = $self->{parser} || $self->_build_parser;
	eval($parser);
	die "Parser ($parser) died:$@" if $@;
	
	if ($self->{diagnostic}) {
		print qq|
		
Entered     = $time_string
Parser		= $parser
		
centuries   = $centuries
years		= $years
months		= $months
weeks		= $weeks
days		= $days
hours		= $hours
minutes		= $minutes
seconds		= $seconds
nanoseconds = $nanoseconds
		|;
	
	}

	$years += ($centuries * 100);
	$days  += ($weeks     * 7  );
	
	return (
		years		=> $years		|| 0,
		months		=> $months		|| 0,
		days		=> $days		|| 0,
		hours		=> $hours		|| 0,
		minutes		=> $minutes		|| 0,
		seconds		=> $seconds		|| 0,
		nanoseconds => $nanoseconds	|| 0,
	);	

}

sub as_weeks {
	my $self = shift;	

	my %deltas = %{$_[0]};
	
	return int($deltas{days} / 7) unless $self and $self->base;
	
	my $dt1 = $self->base + DateTime::Duration->new( %deltas );
	return int(($dt1->{utc_rd_days} - $self->base->{utc_rd_days})/7);
}

sub as_days {
	my $self = shift;	

	my %deltas = %{$_[0]};
	
	return int($deltas{days}) unless $self and $self->base;
	
	my $dt1 = $self->base + DateTime::Duration->new( %deltas );
	return ($dt1->{utc_rd_days} - $self->base->{utc_rd_days});
}

sub as_seconds {
	my $self = shift;	

	my %deltas = %{$_[0]};
	
	return int($deltas{days} * (24*60*60)) unless $self and $self->base;
	
	my $dt1 = $self->base + DateTime::Duration->new( %deltas );
	return int(($dt1->{utc_rd_days} - $self->base->{utc_rd_days}) * (24*60*60)) 
			+ ($dt1->{utc_rd_secs} - $self->base->{utc_rd_secs});
}

sub _format_nanosecs {
	my %deltas = %{+shift};
    my $precision = shift;
    
	my $ret = sprintf( "%09d", $deltas{nanoseconds} );
    return $ret unless $precision;   # default = 9 digits

    my ( $int, $frac ) = split(/[.,]/, $deltas{nanoseconds});
    $ret .= $frac if $frac;

    return substr( $ret, 0, $precision );
}

sub _build_parser {
	my $self = shift;
	my $regex = my $field_list = shift || $self->pattern;
	my @fields = $field_list =~ m/(%\{\w+\}|%\d*.)/g;
	$field_list = join('',@fields);
	
	my $tempdur = DateTime::Duration->new( seconds => 0 ); # Created just so we can do $tempdt->can(..)

	# I'm absoutely certain there's a better way to do this:
	$regex=~s|([\/\.\-])|\\$1|g;
	
	$regex =~ s/%[Tr]/%H:%M:%S/g;
	$field_list =~ s/%[Tr]/%H%M%S/g;
	# %T is the time as %H:%M:%S.

	$regex =~ s/%R/%H:%M/g;
	$field_list =~ s/%R/%H%M/g;
	#is the time as %H:%M.

	$regex =~ s|%F|%Y\\-%m\\-%d|g;
	$field_list =~ s|%F|%Y%m%d|g;
	#is the same as %Y-%m-%d

	# Numerated places:
	
	# Centuries:
	$regex =~ s/%(\d*)[C]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[C]/#centuries#/g;
	
	# Years:
	$regex =~ s/%(\d*)[Y]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[Y]/#years#/g;
	
	# Months:
	$regex =~ s/%(\d*)[m]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[m]/#months#/g;
	
	# Weeks:
	$regex =~ s/%(\d*)[GV]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[GV]/#weeks#/g;
	
	# Days:
	$regex =~ s/%(\d*)[dejuy]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[dejuy]/#days#/g;
	
	# Hours:
	$regex =~ s/%(\d*)[HIkl]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[HIkl]/#hours#/g;
	
	# Minutes:
	$regex =~ s/%(\d*)[M]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[M]/#minutes#/g;
	
	# Seconds:
	$regex =~ s/%(\d*)[sS]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[sS]/#seconds#/g;
	
	# Nanoseconds:
	$regex =~ s/%(\d*)[N]/($1) ? " *(\\d{$1})" : " *(\\d+)"/eg;
	$field_list =~ s/%(\d*)[N]/#nanoseconds#/g;

		
	# Any function in DateTime.
	$regex =~ s|%{(\w+)}|($tempdur->can($1)) ? "(.+)" : ".+"|eg;
	$field_list =~ s|(%{(\w+)})|($tempdur->can($2)) ? "#$2#" : $1 |eg;

	# is replaced by %.
	$regex =~ s/%%/%/g;
	$field_list =~ s/%%//g;

	$field_list=~s/#([a-z0-9_]+)#/\$$1, /gi;
	$field_list=~s/,\s*$//;

	$self->{parser} = qq|($field_list) = \$time_string =~ /$regex/|;
}


1;

__END__

=head1 NAME

DateTime::Format::Duration - Duration objects for date math

=head1 SYNOPSIS

  use DateTime::Format::Duration;

  $d = DateTime::Format::Duration->new(
          pattern => '%P%F %r'
  );
  
  print $d->format_duration( 
     DateTime::Duration->new( 
        years   => 3,
        months  => 5,
        days    => 1,
        hours   => 6,
        minutes => 15,
        seconds => 45, 
        nanoseconds => 12000 
     )
  );
  # 0003-05-01 06:15:45
  
  $duration = $d->parse_duration('0003-05-01 06:15:45');

    
  print $d->format_duration_from_deltas( 
     years   => 3,
     months  => 5,
     days    => 1,
     hours   => 6,
     minutes => 15,
     seconds => 45, 
     nanoseconds => 12000 
  );
  # 0003-05-01 06:15:45
  
  %deltas = $d->parse_duration_as_deltas('0003-05-01 06:15:45');
  

=head1 ABSTRACT

This module attempts to format and parse C<DateTime::Duration> objects
as well as other representations of durations.

=head1 CONSTRUCTOR

This module contains a single constructor:

=over 4

=item * new( ... )

The C<new> constructor takes the following attributes:

=over 4

=item * pattern => $string

This is a strf type pattern detailing the format of the duration.
See the C<PATTERNS> sections below for more information.

=item * normalise => $one_or_zero

=item * normalize => $one_or_zero

This determines whether durations are 'normalised'. For example, does 
120 seconds become 2 minutes? For more information on this option see
the C<NORMALISE> section below. 

By default we normalise on C<DateTime->now()>

=item * base => $datetime_object

If a base DateTime is given then that is the normalisation date. Setting
this attribute overrides the above option and sets normalise to true.

=back

=back

=head1 METHODS

C<DateTime::Format::Duration> has the following methods:

=over 4

=item * format_duration( $datetime_duration_object )

Returns a string representing the duration in the format set by the pattern.

=item * format_duration_from_deltas( %deltas )

As above, this method returns a string representing a duration in the format
set by the pattern. However this method takes a hash of values. Permissable
hash keys are C<years, months, days, hours, minutes, seconds> and C<nanoseconds>

=item * parse_duration( $string )

This method takes a string and returns a DateTime::Duration object that is the
equivalent according to the pattern.

=item * parse_duration_as_deltas( $string )

Once again, this method is the same as above, however it returns a hash rather
than an object.

=item * normalise( $duration_object )

=item * normalize( %deltas )

Returns a hash of deltas after normalising the input. See the C<NORMALISE>
section below for more information.

=back

=head1 ACCESSORS

=over 4

=item * pattern( $optional_new_pattern )

Returns the current pattern after possibly applying a new pattern.

=item * base( $optional_datetime )

Returns the current base after possibly applying a new one.

=item * normalising( $optional_true_or_false )

Indicates whether or not the durations are being normalised after
possibly changing the value.

=back

=head1 PATTERNS

This module uses a similar set of patterns to strftime. These patterns
have been kept as close as possible to the original time-based patterns.

=over 4

=item * %C

The number of hundreds of years in the duration. 400 years would return 4.
This is similar to centuries.

=item * %d

The number of days zero-padded to two digits. 2 days returns 02. 22 days 
returns 22 and 220 days returns 220.

=item * %e

The number of days.

=item * %F

Equivelent of %Y-%m-%d

=item * %H

The number of hours zero-padded to two digits. 

=item * %I

Same as %H

=item * %j

The duration expressed in whole days. 36 hours returns 1

=item * %k

The hours without any padding

=item * %l

Same as %k

=item * %m

The months, zero-padded to two digits

=item * %M

The minutes, zero-padded to two digits

=item * %n

A linebreak when formatting and any whitespace when parsing

=item * %N

Nanoseconds - see note on precision at end

=item * %p

Either a '+' or a '-' indicating the positive-ness of the duration

=item * %P

A '-' for negative durations and nothing for positive durations.

=item * %r

Equivelent of %H:%M:%S

=item * %R

Equivelent of %H:%M

=item * %s

Returns the value as seconds. 1 day, 5 seconds return 86405

=item * %S

Returns the seconds, zero-padded to two digits

=item * %t

A tab character when formatting or any whitespace when parsing

=item * %T

Equivelent of %P%H:%M:%S

=item * %u

Days after weeks are removed. 4 days returns 4, but 22 days returns 1 
(22 days is three weeks, 1 day)

=item * %V

Duration expressed as weeks. 355 days returns 52.

=item * %W

Duration expressed as floating weeks. 10 days, 12 hours returns 1.5 weeks.

=item * %y

Years in the century. 145 years returns 45.

=item * %Y

Years, zero-padded to four digits

=item * %%

A '%' symbol

=back

B<Precision> can be changed for any and all the above values. For all but
nanoseconds (%N), the precision is the zero-padding. To change the precision
insert a number between the '%' and the letter. For example: 1 year formatted
with %6Y would return 000001 rather than the default 0001. Likewise, to remove
padding %1Y would just return a 1.

Nanosecond precision is the other way (nanoseconds are fractional and thus
should be right padded). 123456789 nanoseconds formatted with %3N would return 
123 and formatted as %12N would return 123456789000.

=head1 NORMALISE

This module contains a complex method for normalising durations. The method
ensures that all values are as close to zero as possible. Rather than returning
124 seconds, it is normalised to 2 minutes, 4 seconds.

The complexity comes from two places:

=item * Mixed positivity

The duration of 1 day, minus 2 hours is easy to normalise in your head to
22 hours. However consider something more complex such as -2 years, +1 month,
+22 days, +11 hours, -9 minutes. 

=item * Months of unequal length. 

Unfortunately months can have 28, 29, 30 or 31 days and it can change from year
to year. Thus if I wanted to normalise 2 months it could be any of 59 (Feb-Mar), 
60 (Feb-Mar in a leap year), 61 (Mar-Apr, Apr-May, May-Jun, Jun-Jul, Aug-Sep,
Sep-Oct, Oct-Nov or Nov-Dec) or 62 days (Dec-Jan or Jul-Aug). Because of this
the module uses a base datetime for its calculations. If we use the base 
2003-01-01T00:00:00 then two months would be 59 days (2003-03-01 - 2003-01-01)

=item * Leap seconds

This module currently ignores any leap seconds.

=head1 DELTAS vs DURATION OBJECTS

This module can bypass duration objects and just work with delta hashes. This
is of use for durations that contains mixed positivity. Note the following:

$one = $o->format_duration(
   DateTime::Duration->new(
      years => -2,
      days  => 13,
      hours => -1
   )
);

$two = $o->format_duration_from_deltas(
   years => -2,
   days  => 13,
   hours => -1
);

While these both appear to be the same, the return very different answers:

$one eq '-0002-00-13 02:00:00'

$two eq '-0001-11-18 23:00:00'

This is because DateTime::Duration has been designed to not allow mixed
positivity. If there is one or more negative values then all values are
assumed to be negative. Using deltas allows you to set mixed values.


=head1 AUTHOR

Rick Measham <rickm@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003 Rick Measham.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

