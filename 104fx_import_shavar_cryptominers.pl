#!/usr/bin/perl -s

# This descends from huepl and TTYtter, and is therefore under the Floodgap
# Free Software License. It is not required to build or run Firefox or
# TenFourFox.

BEGIN {
	$VERSION = "v0.5";
        if ($] >= 5.014000 && $ENV{'PERL_SIGNALS'} ne 'unsafe') {
                $signals_use_posix = 1;
        } else {
                $ENV{'PERL_SIGNALS'} = 'unsafe';
        }
}

$lastexception = 0;
@wend = ('-L', '-s', '-m', '20', '-A', '', '-H', 'Expect:');
eval "use POSIX;";
$URL = "https://raw.githubusercontent.com/mozilla-services/shavar-prod-lists/master/disconnect-blacklist.json";

$exit_mode = 0;
$stringify_args = sub {
	my $basecom = shift;
	my $resource = shift;
	my $data = shift;
	my $p;
	my $l = '';

	foreach $p (@_) {
		if ($p =~ /^-/) {
			$l .= "\n" if (length($l));
			$l .= "$p ";
			next;
		}
		$l .= $p;
	}
	$l .= "\n";

	# if resource is an arrayref, then it's a GET with URL
	# and args
	$resource = join('?', @{ $resource })
		if (ref($resource) eq 'ARRAY');
	$l .= "url = \"$resource\"\n";
	$data =~ s/"/\\"/g;
	$l .= "data = \"$data\"\n" if length($data);
	return ("$basecom -K -", $l, undef);
};

sub sigify {
        # this routine abstracts setting signals to a subroutine reference.
        # check and see if we have to use POSIX.pm (Perl 5.14+) or we can
        # still use $SIG for proper signalling. We prefer the latter, but
        # must support the former.
        my $subref = shift;
        my $k;

        if ($signals_use_posix) {
                my @w;
                my $sigaction = POSIX::SigAction->new($subref);
                while ($k = shift) {
                        my $e = &posix_signal_of($k);
                        # some signals may not exist on all systems.
                        next if (!(0+$e));
                        POSIX::sigaction($e, $sigaction)
                                || die("sigaction failure: $! $@\n");
                }
        } else {
                while ($k = shift) { $SIG{$k} = $subref; }
        }
}
sub posix_signal_of {
        die("never call posix_signal_of if signals_use_posix is false\n")
                if (!$signals_use_posix);

        # this assumes that POSIX::SIG* returns a scalar int value.
        # not all signals exist on all systems. this ensures zeroes are
        # returned for locally bogus ones.
        return 0+(eval("return POSIX::SIG".shift));
}

sub parsejson {
	my $data = shift;
	my $my_json_ref = undef; # durrr hat go on foot
	my $i;
	my $tdata;
	my $seed;
	my $bbqqmask;
	my $ddqqmask;
	my $ssqqmask;

	# test for single logicals
	return {
		'ok' => 1,
		'result' => (($1 eq 'true') ? 1 : 0),
		'literal' => $1,
			} if ($data =~ /^['"]?(true|false)['"]?$/);

	# first isolate escaped backslashes with a unique sequence.
	$bbqqmask = "BBQQ";
	$seed = 0;
	$seed++ while ($data =~ /$bbqqmask$seed/);
	$bbqqmask .= $seed;
	$data =~ s/\\\\/$bbqqmask/g;

	# next isolate escaped quotes with another unique sequence.
	$ddqqmask = "DDQQ";
	$seed = 0;
	$seed++ while ($data =~ /$ddqqmask$seed/);
	$ddqqmask .= $seed;
	$data =~ s/\\\"/$ddqqmask/g;

	# then turn literal ' into another unique sequence. you'll see
	# why momentarily.
	$ssqqmask = "SSQQ";
	$seed = 0;
	$seed++ while ($data =~ /$ssqqmask$seed/);
	$ssqqmask .= $seed;
	$data =~ s/\'/$ssqqmask/g;

	# here's why: we're going to turn doublequoted strings into single
	# quoted strings to avoid nastiness like variable interpolation.
	$data =~ s/\"/\'/g;

	# and then we're going to turn the inline ones all back except
	# ssqq, which we'll do last so that our syntax checker still works.
	$data =~ s/$bbqqmask/\\\\/g;
	$data =~ s/$ddqqmask/"/g;

	print STDOUT "$data\n" if ($superverbose);

	# first, generate a syntax tree.
	$tdata = $data;
	1 while $tdata =~ s/'[^']*'//; # empty strings are valid too ...
	$tdata =~ s/-?[0-9]+\.?[0-9]*([eE][+-][0-9]+)?//g;
		# have to handle floats *and* their exponents
	$tdata =~ s/(true|false|null)//g;
	$tdata =~ s/\s//g;

	print STDOUT "$tdata\n" if ($superverbose);

	# now verify the syntax tree.
	# the remaining stuff should just be enclosed in [ ], and only {}:,
	# for example, imagine if a bare semicolon were in this ...
	if ($tdata !~ s/^\[// || $tdata !~ s/\]$// || $tdata =~ /[^{}:,]/) {
		$tdata =~ s/'[^']*$//; # cut trailing strings
		if (($tdata =~ /^\[/ && $tdata !~ /\]$/)
				|| ($tdata =~ /^\{/ && $tdata !~ /\}$/)) {
			# incomplete transmission
			&exception(10, "*** JSON warning: connection cut\n");
			return undef;
		}
		if ($tdata =~ /(^|[^:])\[\]($|[^},])/) { # oddity
			&exception(11, "*** JSON warning: null list\n");
			return undef;
		}
		# at this point all we should have are structural elements.
		# if something other than JSON structure is visible, then
		# the syntax tree is mangled. don't try to run it, it
		# might be unsafe.
		if ($tdata =~ /[^\[\]\{\}:,]/) {
			&exception(99, "*** JSON syntax error\n");
			die(<<"EOF");
--- data received ---
$data
--- syntax tree ---
$tdata
--- JSON PARSING ABORTED DUE TO SYNTAX TREE FAILURE --
EOF
			exit;
			return undef;
		}
	}

	# syntax tree passed, so let's turn it into a Perl reference.
	# have to turn colons into ,s or Perl will gripe. but INTELLIGENTLY!
	1 while
	($data =~ s/([^'])'\s*:\s*(true|false|null|\'|\{|\[|-?[0-9])/\1\',\2/);

	# removing whitespace to improve interpretation speed actually made
	# it SLOWER.
	#($data =~ s/'\s*,\s*/',/sg);
	#($data =~ s/\n\s*//sg);

	# finally, single quotes, just before interpretation.
	$data =~ s/$ssqqmask/\\'/g;

	# now somewhat validated, so safe (?) to eval() into a Perl struct
	eval "\$my_json_ref = $data;";
	print STDOUT "$data => $my_json_ref $@\n"  if ($superverbose);

	# do a sanity check
	if (!defined($my_json_ref)) {
		&exception(99, "*** JSON syntax error\n");
		print STDOUT <<"EOF" if ($verbose);
--- data received ---
$data
--- syntax tree ---
$tdata
--- JSON PARSING FAILED --
$@
--- JSON PARSING FAILED --
EOF
	}

	return $my_json_ref;
}

sub backticks {
	# more efficient/flexible backticks system
	my $comm = shift;
	my $rerr = shift;
	my $rout = shift;
	my $resource = shift;
	my $data = shift;
	my $dont_do_auth = shift;
	my $buf = '';
	my $undersave = $_;
	my $pid;
	my $args;

	($comm, $args, $data) = &$stringify_args($comm, $resource,
		$data, $dont_do_auth, @_);
	print STDOUT "$comm\n$args\n$data\n" if ($superverbose);
	if(open(BACTIX, '-|')) {
		while(<BACTIX>) {
			$buf .= $_;
		} close(BACTIX);
		$_ = $undersave;
		return $buf; # and $? is still in $?
	} else {
		$in_backticks = 1;
		&sigify(sub {
			die(
		"** user agent not honouring timeout (caught by sigalarm)\n");
		}, qw(ALRM));
		alarm 120; # this should be sufficient
		if (length($rerr)) {
			close(STDERR); 
			open(STDERR, ">$rerr");
		}
		if (length($rout)) {
			close(STDOUT);
			open(STDOUT, ">$rout");
		}
		if(open(FRONTIX, "|$comm")) {
			print FRONTIX "$args\n";
			print FRONTIX "$data" if (length($data));
			close(FRONTIX);
		} else {
			die(
			"backticks() failure for $comm $rerr $rout @_: $!\n");
		}
		$rv = $? >> 8;
		exit $rv;
	}
}

sub wherecheck {
	my ($prompt, $filename, $fatal) = (@_);
	my (@paths) = split(/\:/, $ENV{'PATH'});
	my $setv = '';

	push(@paths, '/usr/bin'); # the usual place
	@paths = ('') if ($filename =~ m#^/#); # for absolute paths

	foreach(@paths) {
		if (-r "$_/$filename") {
			$setv = "$_/$filename";
			1 while $setv =~ s#//#/#;
			last;
		}
	}
	if (!length($setv)) {
		die ($fatal) if ($fatal);
		exit(1);
	}
	return $setv;
}

sub url_oauth_sub {
        my $x = shift;
        $x =~ s/([^-0-9a-zA-Z._~])/"%".uc(unpack("H*",$1))/eg; return $x;
}

# this is a sucky nonce generator. I was looking for an awesome nonce
# generator, and then I realized it would only be used once, so who cares?
# *rimshot*
sub generate_nonce { unpack("H32", pack("u", rand($$).$$.time())); }

sub exception {
	my ($num, $tex) = (@_);
	$lastexception = $num;
	print STDOUT "$tex" if ($verbose);
}

sub grabjson {
	my $url = shift;
	my $no_auth = shift;
	my $data;
	chomp($data = &backticks($curl,
			'/dev/null', undef, $url, undef,
			$no_auth, @wind));
	return &genericnetworkjson($data, $url, $no_auth);
}
sub postjson {
	my $url = shift;
	my $postdata = shift;
	my $no_auth = shift;
	my $data;
	chomp($data = &backticks($curl,
			'/dev/null', undef, $url, $postdata,
			$no_auth, @wend));
	return &genericnetworkjson($data, $url, $no_auth);
}
sub putjson {
	my $url = shift;
	my $postdata = shift;
	my $no_auth = shift;
	my $data;
	chomp($data = &backticks($curl,
			'/dev/null', undef, $url, $postdata,
			$no_auth, @wund));
	return &genericnetworkjson($data, $url, $no_auth);
}

sub genericnetworkjson {
	my $data = shift;
	my $url = shift;
	my $no_auth = shift;
	my $my_json_ref = undef; # durrr hat go on foot
	my $i;
	my $tdata;
	my $seed;

	my $k = $? >> 8;
	$data =~ s/[\r\l\n\s]*$//s;
	$data =~ s/^[\r\l\n\s]*//s;

	if (!length($data) || $k == 28 || $k == 7 || $k == 35) {
		&exception(1, "*** warning: timeout or no data\n");
		return undef;
	}

	if ($k > 0) {
		&exception(4,
"*** warning: unexpected error code ($k) from user agent\n");
		return undef;
	}

	# handle things like 304, or other things that look like HTTP
	# error codes
	if ($data =~ m#^HTTP/\d\.\d\s+(\d+)\s+#) {
		$code = 0+$1;
		print $stdout $data if ($superverbose);

		# 304 is actually a cop-out code and is not usually
		# returned, so we should consider it a non-fatal error
		if ($code == 304 || $code == 200 || $code == 204) {
			&exception(1, "*** warning: timeout or no data\n");
			return undef;
		}
		&exception(4,
"*** warning: unexpected HTTP return code $code from server\n");
		return undef;
	}

	$my_json_ref = &parsejson($data);
	$laststatus = 0;
	return $my_json_ref;
}

$curl ||= &wherecheck("checking for cURL", "curl", <<"EOF");

cURL is required. if cURL is not usually in your path, you can
hardcode it with -curl=/path/to/curl

EOF

$vv = `$curl --version`;
($vv =~ /^curl (\d+)\.(\d+)/) && ($major = $1, $minor = $2);
die("at least cURL 7.58 required, you have ${major}.${minor}.\n\n$vv\n")
	if ($major < 7 || ($major == 7 && $minor < 58));

$json_ref = &grabjson("https://raw.githubusercontent.com/mozilla-services/shavar-prod-lists/master/disconnect-blacklist.json");

die("this doesn't look like the right format\n\ncheck URL\n$url\n")
if (!defined($json_ref->{'license'}) ||
    !defined($json_ref->{'categories'}) ||
    !defined($json_ref->{'categories'}->{'Cryptomining'}));

select(STDOUT); $|++;
%dupedupe = ();
foreach $a (@{ $json_ref->{'categories'}->{'Cryptomining'} }) {
	foreach $b (keys(%{ $a })) {
		die("illegal newline: $b\n") if ($b =~ /[\r\n]/s);
		print "// $b\n";

		foreach $c (keys(%{ $a->{$b} })) {
			next if ($c eq 'performance');
			die("illegal newline: $c\n") if ($c =~ /[\r\n]/s);

			print "//    $c\n";
			foreach $d (@{ $a->{$b}->{$c} }) {
				die("illegal quote: $d\n") if ($d =~ /"/);
				next if ($dupedupe{$d}++);

				print "        BLOK(\"$d\") ||\n";
			}
		}
	}
}
