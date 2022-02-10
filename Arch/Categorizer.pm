package Arch::Categorizer;

use AI::Categorizer;
use AI::Categorizer::Learner::NaiveBayes;
use AI::Categorizer::Learner::SVM;
use Manager::Dialog qw(Message);

use Data::Dumper;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / Entries CategoryNames Categories Built KnowledgeSet Learner
   Documents /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Entries($args{Entries});
  $self->CategoryNames($args{CategoryNames});
  $self->Categories({});
  $self->Documents([]);
}

sub Rebuild {
  my ($self,%args) = @_;
  Message(Message => "Rebuilding index...");
  # add categories
  foreach my $category (@{$self->CategoryNames}) {
    $self->Categories->{$category} =
      AI::Categorizer::Category->by_name
	  (name => $category);
  }

  # add all the documents
  my $i = 0;
  foreach my $entry (keys %{$self->Entries}) {
    if ($entry) {
      my @categories;
      foreach my $category (keys %{$self->Entries->{$entry}}) {
	push @categories, $self->Categories->{$category};
      }
      my $d = AI::Categorizer::Document->new
	(name => $i++,
	 content => $entry,
	 categories => \@categories);
      foreach my $category (@categories) {
	$category->add_document($d);
      }
      push @{$self->Documents}, $d;
    }
  }
  $self->KnowledgeSet
    (AI::Categorizer::KnowledgeSet->new
     (categories => [values %{$self->Categories}],
      documents => $self->Documents));
  $self->Learner
    (AI::Categorizer::Learner::SVM->new());
  $self->Learner->train
    (knowledge_set => $self->KnowledgeSet);
  $self->Built(1);
  Message(Message => "Done rebuilding index.");
}

sub Save {
  my ($self,%args) = @_;
  $self->Learner->save_state
    ($args{ModelDir});
}

sub Load {
  my ($self,%args) = @_;
  $self->Learner
    (AI::Categorizer::Learner::SVM->restore_state($args{ModelDir}));
#   $self->Learner->restore_state
#     ($args{ModelDir});
  $self->Built(1);
}

sub ClassifyEntry {
  my ($self,%args) = @_;
  if (! defined $self->Built) {
    $self->RebuildIndex;
  }
  my $d = AI::Categorizer::Document->new
    (name => $args{Name},
     content => $args{Content});
  my $hypothesis = $self->Learner->categorize($d);
  my @matches = $hypothesis->categories;
  my @results = $hypothesis->scores(@matches);
  my $h = {};
  while (@matches) {
    my $category = shift @matches;
    shift @results;
    my $score = shift @results;
    $h->{$category} = $score;
  }
  return $h;
}

1;

