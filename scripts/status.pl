#!/usr/bin/perl -w

# program to tell the status of a given package
# should this be in RADAR, and Packager, to record what they have done.
# can have an alignment by asking the user to disambiguate 

# We need to add information about software from CSO and or other sources.
# Uniquely identify the software and version.
# Determine the status, namely.

# Probability that a user has seen the short description for so long and so many times.
# Probability that a user has seen the long description for so long and so many times.
# How new the system is.
# Whether the user has downloaded the software.
# Whether the user has packaged the software.
# Whether the user has installed the software.
# Whether the user has reviewed the software and what the review was.
# Whether the system satisfies its intended usages.
# Where the location of the downloaded system is at.

use PerlLib::MySQL;

my $mymysql = PerlLib::MySQL->new(DBName => "cso");

sub FixStatus {
  # go through the system and find files that indicate things are a certain way and generate a freekbs script
  foreach my $system (split /\n/, `ls /var/lib/myfrdcsa/codebases/external/`) {
    $system =~ s/-.*//;
    # now look it up 
  }
}

FixStatus();
