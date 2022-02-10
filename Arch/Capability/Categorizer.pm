package Arch::Capability::Categorizer;

use Arch::Categorizer;
use BOSS::ICodebase qw(GetSystems);
use Manager::Dialog qw(QueryUser);
use MyFRDCSA;
use PerlLib::Util qw(ExistsRecent SaveDataToFile);

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Capabilities Categorizer Counter Descriptions /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Counter(10000000 - 1);
  $self->UpdateCapabilityMap
    (CapabilityFile => $args{CapabilityFile} ||
     "/var/lib/myfrdcsa/codebases/internal/architect/data/capability-map.pl");
  $self->LoadCategorizer();
}

sub UpdateCapabilityMap {
  my ($self,%args) = @_;
  my $r = ExistsRecent
    (File => $args{CapabilityFile},
     Within => 86400*3);
  if (! exists $r->{Recent}) {
    my $systems = GetSystems
      (Dirs => [Dir("internal codebases")]);
    $self->Capabilities({});
    foreach my $system (sort keys %$systems) {
      print "$system\n";
      my $res = BOSS::ICodebase::Capabilities($system);
      foreach my $cap (@{$res->[0]}) {
	$cap =~ s/\b$system\b/thisystem/ig;
	$self->Capabilities->{$system}->{$cap} = 1;
      }
    }
    # save them
    SaveDataToFile
      (Data => Dumper($self->Capabilities),
       File => )
    } else {
      # go ahead an load it
      my $capabilityfile = $args{CapabilityFile};
      my $c = `cat "$capabilityfile"`;
      my $e = eval $c;
      $self->Capabilities($e);
    }

  # now that we have the capabilities, print them
  # print Dumper($self->Capabilities);
}

sub LoadCategorizer {
  my ($self,%args) = @_;
  my $modeldir = "/var/lib/myfrdcsa/codebases/internal/architect/data/capability-model.svm";
  my $descfile = "/var/lib/myfrdcsa/codebases/internal/architect/data/descriptions.pl";
  my $c = `cat "$descfile"`;
  $self->Descriptions(eval $c);

  # now build the categorizer information
  my $entries = {};
  my $cats = {};
  foreach my $k (keys %{$self->Descriptions}) {
    foreach my $i (@{$self->Descriptions->{$k}}) {
      $entries->{$i}->{$k} = 1;
      $cats->{$k} = 1;
    }
  }
  foreach my $k (keys %{$self->Capabilities}) {
    foreach my $i (keys %{$self->Capabilities->{$k}}) {
      $entries->{$i}->{$k} = 1;
      $cats->{$k} = 1;
    }
  }
  $self->Categorizer
    (Arch::Categorizer->new
     (CategoryNames => [keys %$cats],
      Entries => $entries));
  if (! -d $modeldir) {
    $self->Categorizer->Rebuild;
    $self->Categorizer->Save
      (ModelDir => $modeldir);
  } else {
    $self->Categorizer->Load
      (ModelDir => $modeldir);
  }
}

sub ClassifyCapability {
  my ($self,%args) = @_;
  $self->Counter($self->Counter + 1);
  return $self->Categorizer->ClassifyEntry
    (Name => $self->Counter,
     Content => $args{Capability});
}

sub ElicitCapbilities {
  my ($self,%args) = @_;
  # load existing systems and functionality from capabilities management system
  while (1) {
    my $capability = $args{Query} || QueryUser("Describe the functionality:");
    print Dumper
      ($self->ClassifyCapability
       (Capability => $capability));
  }
}

1;
