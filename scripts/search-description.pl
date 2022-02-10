#!/usr/bin/perl -w

my $f = "/var/lib/myfrdcsa/codebases/internal/architect/data/descriptions.pl";
my $c = `cat "$f"`;
my $e = eval $c;

my $search = $ARGV[0];

foreach my $k (sort keys %$e) {
  my $match;
  if (scalar @{$e->{$k}}) {
    foreach my $l (@{$e->{$k}}) {
      if ($l =~ /$search/i) {
	$match = 1;
      }
    }
  }
  if ($match) {
    print "File:\t$k\n";
    foreach my $l (@{$e->{$k}}) {
      print "\t$l\n";
    }
    print "\n";
  }
}
