#!/usr/bin/perl -w

my $f = "/var/lib/myfrdcsa/codebases/internal/architect/data/descriptions.pl";
my $c = `cat "$f"`;
my $e = eval $c;

my @later;

foreach my $k (sort keys %$e) {
  if (scalar @{$e->{$k}}) {
    print "File:\t$k\n";
    foreach my $l (@{$e->{$k}}) {
      print "\t$l\n";
    }
    print "\n";
  } else {
    push @later, $k;
  }
}

foreach my $f (@later) {
  print "$f\n";
}
