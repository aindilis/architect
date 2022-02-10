#!/usr/bin/perl -w

use FWeb::FRDCSA;

use Data::Dumper;

my $icodebasedir = "/var/lib/myfrdcsa/codebases/internal/";
foreach my $dir (split /\n/, `ls $icodebasedir`) {
  chomp $dir;
  my $file = "$icodebasedir/$dir/frdcsa/FRDCSA.xml";
  if (-f $file) {
    my $item = FWeb::FRDCSA->new
      (SubsystemDescriptionFile => $file);
    my $desc = $item->ShortDesc;
    $desc =~ s/^\s+//g;
    $desc =~ s/\s+$//g;
    $desc =~ s/\n/ /g;
    $desc =~ s/\s+/ /g;
    print "[\"icodebase-short-description\", \"$dir\",\"$desc\"],\n";
  }
}
