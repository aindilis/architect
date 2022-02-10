package Arch::Capability::Generator;

# an attempt to build a controlled english using ngrams as a starting
# point

# $self->Parser->opts("max_parse_time",3);

use Corpus;
use Data::Dumper;
use Lingua::EN::Sentence qw(get_sentences);
use String::Tokenizer;
use System::LinkParser;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / AllSentences MyCorpus Max Ngrams Parser Res Sum Tokenizer /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Parser
    (System::LinkParser->new);
  $self->Tokenizer
    (String::Tokenizer->new);

  $self->MyCorpus
    (Corpus->new);
  $self->Res
    ($self->MyCorpus->ListRecent
     (Depth => 50000));

  $self->AllSentences({});
  $self->Max({});
  $self->Ngrams({});
  $self->Sum({});

  $self->ProcessNGrams();
}

sub GenerateRandomWalk {
  my ($self,%args) = @_;
  # add a random walk generator to test
  my @lead = ("START");
  my $total = {};
  my $nexttoken;
  my @sentence;
  while ($nexttoken ne "END" and $nexttoken ne "PREMATUREEND") {
    if (scalar @lead == 1) {
      # get the next key and push it onto the lead
      my @l = keys %{$self->Ngrams->{2}->{$lead[0]}};
      $nexttoken = "";
      my $count = 0;
      while (! $nexttoken and $count < 1000) {
	# choose a random token from the list
	my $possible = $l[rand(scalar @l)];
	if ($self->Ngrams->{2}->{$lead[0]}->{$possible} > rand($self->Max->{1}->{$lead[0]})) {
	  $nexttoken = $possible;
	}
	++$count;
      }
      if ($count == 1000) {
	$nexttoken = "PREMATUREEND";
      }
      push @lead, $nexttoken;
    } elsif (scalar @lead == 2) {
      # get the next key and push it onto the lead
      my @l = keys %{$self->Ngrams->{3}->{$lead[0]}->{$lead[1]}};
      $nexttoken = "";
      my $count = 0;
      while (! $nexttoken and $count < 1000) {
	# choose a random token from the list
	my $possible = $l[rand(scalar @l)];
	if ($self->Ngrams->{3}->{$lead[0]}->{$lead[1]}->{$possible} > rand($self->Max->{2}->{$lead[0]}->{$lead[1]})) {
	  $nexttoken = $possible;
	}
	++$count;
      }
      if ($count == 1000) {
	$nexttoken = "PREMATUREEND";
      }
      push @lead, $nexttoken;
      # get the next key from the pair
    } elsif (scalar @lead == 3) {
      my $l = shift @lead;
      push @sentence, $l;
    }
  }
  push @sentence, ,@lead;
  return \@sentence;
}

sub AddNgrams {
  my ($self,%args) = @_;
  my $ts = $args{Tokens};
  my $queues = [];
  foreach my $i (1..$args{N}) {
    my @tokens = @$ts;
    my @q;
    while (@tokens) {
      my $t = shift @tokens;
      $t =~ s/\W+//g;
      push @q, $t;
      if (scalar @q >= $i) {
	my $exp = "\$self->Ngrams->{$i}->{\"".join("\"}->{\"",@q)."\"}++;";
	eval $exp;
	shift @q;
      }
    }
  }
}

sub TallyCounts {
  my ($self,%args) = @_;
  foreach my $i (1..3) {
    foreach my $k1 (%{$self->Ngrams->{$i}}) {
      if ($i <= 1) {
	$self->Sum->{$i} += $self->Ngrams->{$i}->{$k1};
	if ($self->Ngrams->{$i}->{$k1} > $self->Max->{$i}) {
	  $self->Max->{$i} = $self->Ngrams->{$i}->{$k1};
	}
      } elsif ($i <= 2) {
	foreach my $k2 (%{$self->Ngrams->{$i}->{$k1}}) {
	  if ($i == 2) {
	    $self->Sum->{$i}->{$k1} += $self->Ngrams->{$i}->{$k1}->{$k2};
	    if ($self->Ngrams->{$i}->{$k1}->{$k2} > $self->Max->{$i}->{$k1}) {
	      $self->Max->{$i}->{$k1} = $self->Ngrams->{$i}->{$k1}->{$k2};
	    }
	  } elsif ($i == 3) {
	    foreach my $k3 (%{$self->Ngrams->{$i}->{$k1}->{$k2}}) {
	      $self->Sum->{$i}->{$k1}->{$k2} += $self->Ngrams->{$i}->{$k1}->{$k2}->{$k3};
	      if ($self->Ngrams->{$i}->{$k1}->{$k2}->{$k3} > $self->Max->{$i}->{$k1}->{$k2}) {
		$self->Max->{$i}->{$k1}->{$k2} = $self->Ngrams->{$i}->{$k1}->{$k2}->{$k3};
	      }
	    }
	  }
	}
      }
    }
  }
}

sub ProcessNGrams {
  my ($self,%args) = @_;
  my $i = 0;
  foreach my $entry (@{$self->Res}) {
    my $sentences = get_sentences($entry);
    foreach my $sentence (@$sentences) {
      # get ngrams, first tokenize
      $self->Tokenizer->tokenize($entry);
      my @tokens = $self->Tokenizer->getTokens;
      $self->AllSentences->{join(" ",@tokens)} = 1;
      unshift @tokens, "START";
      push @tokens, "END";
      $self->AddNgrams(N => 3,
		Tokens => \@tokens);
    }
    if (!($i % 100)) {
      print "$i\n"
    }
    ++$i;
  }
  $self->TallyCounts;
}

sub Generate {
  my ($self,%args) = @_;
  my @results;
  while (scalar @results < ($args{Count}||1)) {
    my $list = $self->GenerateRandomWalk;
    shift @$list;
    pop @$list;
    my $sentence = join(" ",@$list);
    if ($sentence and ! exists $self->AllSentences->{$sentence}) {
      $self->AllSentences->{$sentence} = 1;
      if ($self->Parser->CheckSentence
	  (Sentence => $sentence)) {
	push @results,$sentence;
      }
    }
  }
  return \@results;
}

1;
