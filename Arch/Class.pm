package APP::Class;

# sample class

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Attribute /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Attribute($args{Attribute} || "");
}

sub Method {
  my ($self,%args) = (shift,@_);
}

1;
