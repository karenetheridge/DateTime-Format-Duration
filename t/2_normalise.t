# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;

#########################

use Test::More tests=>10;

$strf = DateTime::Format::Duration->new(
	base => DateTime->new( year=> 2003 ),
	pattern => '%F %r',
);

@tests = (
	{
		pattern	=>  '%FT%r',
		data	=>  '2003-11-10T14:22:34',
	},
	{
		pattern	=>  '%F %r',
		data	=>  '2003-11-10 14:22:34',
	},
	{
		pattern	=>  '%F %r',
		data	=>  '2003-11-10 149:22:34',
		expect	=>  '2003-11-16 05:22:34', 
		title	=>  '%F %r with normalisation',
	},
	{
		pattern	=>  '%2Y-%3m-%2d %r',
		data	=>  '00-000-00 149:22:34',
		expect	=>  '00-000-06 05:22:34', 
		title	=>  '%F %r with normalisation and field length',
	},
	{
		pattern	=>  '%2C%2Y',
		data	=>  '2003',
		title	=>  '%2C%2Y Centuries and Years, should work the same as %4Y',
	},
	{
		pattern	=>  '%4Y',
		data	=>  '2003',
		title	=>  '%4Y to prove the point',
	},
	{
		pattern	=>  '%V',
		data	=>  '12',
	},
	{
		pattern	=>  '%V extra',
		data	=>  '12 extra',
		title	=>  'Extraneous gibberish',
	},
	{
		diag	=>	0,
		pattern	=>  '%Y %m %d',
		data	=>  '   2003    10     3',
		expect	=>	'2003 10 03',
		title	=>  'Extraneous whitespace',
	},
	{
		diag	=>	0,
		pattern	=>  '%Y-%m-%d',
		data	=>  '2003-10-32',
		expect	=>	'2003-11-02',
		title	=>  'Month based normalisation',
	},

);

foreach my $test (@tests) {
	$test->{title} ||= $test->{pattern};
	$test->{expect} ||= $test->{data};
	$strf->pattern( $test->{pattern} );
	$strf->{diagnostic} = 1 if $test->{diag};
	is( 
		$strf->format_duration(
			$strf->parse_duration(
				$test->{data}
			),
		),
		$test->{expect},
		$test->{title}
	) or diag( "Failed parser: " . $strf->{parser} . " on " . $test->{pattern} . " for " . $test->{data} ) . 
		 diag( "Got: " . Dump(  {$strf->parse_duration_as_deltas( $test->{data} )} ));
	$strf->{diagnostic} = 0;
}


sub Dump {
	eval{
		require Data::Dumper
	};
	return "<Couldn't load Data::Dumper>" if $@;
	return Data::Dumper::Dumper(@_)
}
