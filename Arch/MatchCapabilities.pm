package Arch::MatchCapabilities;

# this version only looks at apt-cache, but in theory should utilize
# CSO, right?  also should be promoted into a module
# consider using Text::PhraseDistance, or similar

use Manager::Dialog qw (ApproveCommands QueryUser SubsetSelect);

use Data::Dumper;
use PerlLib::MySQL;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / ContentsFile Method MyMySQL Num Searches /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Method("cso");
  if ($args{ContentsFile}) {
    my $contentsfile = $self->Contentsfile;
    $self->ContentsFile($contentsfile);
    my @searches = split /\n/,`cat $contentsfile`;
    $self->Searches(\@searches);
  } else {
    $self->Searches([]);
  }
  $self->MyMySQL
    (PerlLib::MySQL->new
     (DBName => "cso"));
  $self->Num(0);



}

sub Execute {
  my ($self,%args) = @_;
  $self->GenerateLanguageModel();
  $self->ChoosePackageProvidingRequirement();
}

sub GenerateLanguageModel {
  my ($self) = @_;
  print "Generating Language Model\n";
  my @corpus;
  if ($self->Method eq "apt-cache") {
    my $results = `apt-cache search -f .`;
    foreach my $entry (split /\n\n/, $results) {
      $entry =~ /Description: (.*?)\n(.*)(^\S+:)?/sm;
      push @corpus, "$1\n$2";
    }
  } elsif ($self->Method eq "cso") {
    my $results = $self->MyMySQL->Do
      (Statement => "select * from systems");
    foreach my $key (keys %$results) {
      push @corpus, join("\n",($results->{$key}->{Name} || "",
			       $results->{$key}->{ShortDesc} || "",
			       $results->{$key}->{LongDesc} || ""));
    }
  }
  print "Generating IDF\n";
  my $num = 0;
  foreach my $word (split /\W+/, join("\n",@corpus)) {
    if (defined $freq{$word}) {
      $freq{$word} += 1;
    } else {
      $freq{$word} = 1;
    }
    ++$num;
  }
  $self->Num($num);
  print "Done Generating Language Model\n";
}

sub ChoosePackageProvidingRequirement {
  my ($self) = @_;
  while (1) {
    my $line;
    if (scalar @{$self->Searches}) {
      $line = shift @{$self->Searches};
    } else {
      $line = QueryUser("Next Search: ");
    }
    my %score;
    chomp $line;
    my @keywords = split /\W+/, $line;
    foreach my $keyword (@keywords) {
      if (length $keyword > 3) {
	if ($self->Method eq "apt-cache") {
	  foreach my $result (split /\n/, `apt-cache search $keyword`) {
	    if ($result =~ / - .*/) {
	      if ($freq{$keyword}) {
		$score{$result} += ($self->Num / $freq{$keyword});
	      }
	    }
	  }
	} elsif ($self->Method eq "cso") {
	  # use stop words to get rid of massive searches later on
	  my $results = $self->MyMySQL->Do
	    (Statement =>
	     "select * from systems where Name like '%$keyword%' or ShortDesc like '%$keyword%' or LongDesc like '%$keyword'");
	  # get a count of how frequently the term shows up
	  # do TFIDF here
	  foreach my $key (keys %$results) {
	    if ($freq{$keyword}) {
	      $score{$results->{$key}->{ID}.": ".$results->{$key}->{Name}." - ".$results->{$key}->{ShortDesc}} +=
		($self->Num / $freq{$keyword});
	    }
	  }
	}
      }
    }
    my @top = sort {$score{$a} <=> $score{$b}} keys %score;
    #print "\n\n$line\n".Dumper(@keywords).Dumper(reverse map {[$_,$score{$_}]} splice (@top,-10));
    print "\n\n<$line>\n";
    my $set;
    if (@top > 20) {
      $set = [reverse splice (@top,-20)]
    } else {
      $set = [reverse @top];
    }
    foreach my $res (SubsetSelect
		     (Set => $set,
		      Selection => {})) {
      if ($self->Method eq "apt-cache") {
	$res =~ s/ - .*//;
	push @results, $res;
      } elsif ($self->Method eq "cso") {
	$res =~ s/:.*//;
	# now we want to save into some persistance database this
	# information
      }
    }
  }
}

1;
