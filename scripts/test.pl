#!/usr/bin/perl -w

use Arch::Capability::Generator;
use Data::Dumper;

my $g = Arch::Capability::Generator->new;

print Dumper($g->Generate(Count => 10));
