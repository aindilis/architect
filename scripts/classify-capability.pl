#!/usr/bin/perl -w

use Arch::Categorizer;
use BOSS::ICodebase qw(GetSystems);
use Manager::Dialog qw(QueryUser);
use MyFRDCSA;
use PerlLib::Util qw(ExistsRecent SaveDataToFile);

use Data::Dumper;

$capabilities;
$descriptions;
$categorizer;

sub UpdateCapabilityMap {
  my $capabilityfile = "/var/lib/myfrdcsa/codebases/internal/architect/data/capability-map.pl";
  my $r = ExistsRecent
    (File => $capabilityfile,
     Within => 86400*3);
  if (! exists $r->{Recent}) {
    my $systems = GetSystems
      (Dirs => [Dir("internal codebases")]);
    $capabilities= {};
    foreach my $system (sort keys %$systems) {
      print "$system\n";
      my $res = BOSS::ICodebase::Capabilities($system);
      foreach my $cap (@{$res->[0]}) {
	$cap =~ s/\b$system\b/thisystem/ig;
	$capabilities->{$system}->{$cap} = 1;
      }
    }
    # save them
    SaveDataToFile
      (Data => Dumper($capabilities),
       File => $capabilityfile)
    } else {
      # go ahead an load it
      my $c = `cat "$capabilityfile"`;
      $capabilities = eval $c;
    }

  # now that we have the capabilities, print them
  # print Dumper($capabilities);
}

sub LoadCategorizer {
  my %args = @_;
  my $modeldir = "/var/lib/myfrdcsa/codebases/internal/architect/data/capability-model.svm";
  my $descfile = "/var/lib/myfrdcsa/codebases/internal/architect/data/descriptions.pl";
  my $c = `cat "$descfile"`;
  $descriptions = eval $c;

  # now build the categorizer information
  my $entries = {};
  my $cats = {};
  foreach my $k (keys %$descriptions) {
    foreach my $i (@{$descriptions->{$k}}) {
      $entries->{$i}->{$k} = 1;
      $cats->{$k} = 1;
    }
  }
  foreach my $k (keys %$capabilities) {
    foreach my $i (keys %{$capabilities->{$k}}) {
      $entries->{$i}->{$k} = 1;
      $cats->{$k} = 1;
    }
  }
  $categorizer = Arch::Categorizer->new
    (CategoryNames => [keys %$cats],
     Entries => $entries);
  if (! -d $modeldir) {
    $categorizer->Rebuild;
    $categorizer->Save
      (ModelDir => $modeldir);
  } else {
    $categorizer->Load
      (ModelDir => $modeldir);
  }
}

sub FindPlaceFor {
  # load existing systems and functionality from capabilities management system
  my $i = 10000000;
  while (1) {
    my $functionality = $args{Query} || QueryUser("Describe the functionality:");
    print $functionality."\n";
    if (0) {
      my @locations =
	SubsetSelect
	  (Set =>
	   [qw(Projects ICodebases ECodebases)]);
    }
    print Dumper
      ($categorizer->ClassifyEntry
       (Name => $i++,
	Content => $functionality));
  }
}

sub BuildRandomSystems {
  # load existing systems and functionality from capabilities management system
  my $i = 1000000;
  my $systems = {};
  foreach my $functionality (split /\n/, `cat entries`) {
    my $res = $categorizer->ClassifyEntry
      (Name => $i++,
       Content => $functionality);
    foreach my $k (keys %$res) {
      $systems->{$k}->{$functionality} = 1;
    }
  }
  print Dumper($systems);
}

UpdateCapabilityMap();
LoadCategorizer();
FindPlaceFor();
# BuildRandomSystems();
