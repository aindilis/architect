package Arch;

use Arch::Capability::Categorizer;
use Arch::Capability::Generator;
use BOSS::Config;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config MyCategorizer MyGenerator /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $specification = "
	-s			Review unimplemented requirements from internal codebases and locate
 				corresponding external codebases
	-l <capability>		Locate software systems that implement or should implement this

	-r <count>		Generate a random system with count capabilities
";
  $self->Config(BOSS::Config->new
		(Spec => $specification,
		 ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  $self->MyCategorizer
    (Arch::Capability::Categorizer->new);
  $self->MyGenerator
    (Arch::Capability::Generator->new);
  if (exists $conf->{'-u'}) {
    $UNIVERSAL::agent->Register
      (Host => defined $conf->{-u}->{'<host>'} ?
       $conf->{-u}->{'<host>'} : "localhost",
       Port => defined $conf->{-u}->{'<port>'} ?
       $conf->{-u}->{'<port>'} : "9000");
  }
}

sub Execute {
  my ($self,%args) = (shift,@_);
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-r'}) {
    $self->BuildRandomSystems
      (Count => $conf->{'-r'});
  }
}

sub BuildRandomSystems {
  my ($self,%args) = @_;
  # load existing systems and functionality from capabilities management system
  my $i = 1000000;
  my $systems = {};
  foreach my $capability 
    (@{$self->MyGenerator->Generate
	 (Count => $args{Count})}) {
    my $res = $self->MyCategorizer->ClassifyCapability
      (Capability => $capability);
    foreach my $k (keys %$res) {
      $systems->{$k}->{$capability} = 1;
    }
  }
  print Dumper($systems);
}

1;
