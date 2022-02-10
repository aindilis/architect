#!/usr/bin/perl -w

# formalize the capabilities of an agent

use Manager::Dialog qw(Approve);
use System::MontyLingua;

use Data::Dumper;

my $OUT;
open(OUT,">/tmp/assertions") or die "ouch\n";

my $ml = System::MontyLingua->new();
$ml->StartServer();

sub ExtractUses {
  my %args = @_;
  my $cap = eval `boss capabilities $args{System}`;

  my $seen = {};
  foreach my $text (@$cap) {
    my $res = $ml->ApplyMontyLinguaToText
      (Text => $text)->[0];
    if (! exists $res->{Fail}) {
      my $list = eval "\$VAR1 = ".$res->{Results}->{relations}.";";
      foreach my $item (@$list) {
	if (! $seen->{Dumper($item)}) {
	  if ($item->[0] eq "use") {
	    print OUT "KBS, MySQL:freekbs:architect assert (".
	      join(" ",map "\"$_\"", @$item).
		")"."\n";
	  }
	}
	$seen->{Dumper($item)}++;
      }
    }
  }
}

my @systems = split /\n/, `ls /var/lib/myfrdcsa/codebases/internal`;
foreach my $system (splice @systems,0,3) {
  ExtractUses(System => $system);
}
close(OUT);

system "cat /tmp/assertions | sort -u";
