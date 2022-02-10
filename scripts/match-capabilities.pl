#!/usr/bin/perl -w

use Arch::MatchCapabilities;

my $matchcapabilities = Arch::MatchCapabilities->new();
# (ContentsFile => "/var/lib/myfrdcsa/codebases/internal/architect/data/systems/extracted-redux");
$matchcapabilities->Execute(Items => \@ARGV);
