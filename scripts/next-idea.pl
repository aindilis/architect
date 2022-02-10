#!/usr/bin/perl -w

my $file = "/var/lib/myfrdcsa/codebases/internal/architect/scripts/entries";
if (! -f $file) {
  print "No entries found\n";
} else {
  my $c = `cat "$file"`;
  my @lines = split /\n/, $c;
  my $l = shift @lines;
  print $l."\n";
  my $OUT;
  open(OUT,">$file") or die "can't open file for writing\n";
  print OUT join("\n",(@lines,$l));
  close(OUT);
}
