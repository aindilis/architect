#!/usr/bin/perl -w

# an attempt to build a controlled english using ngrams as a starting point

use Corpus;

use Data::Dumper;
use Lingua::EN::Sentence qw(get_sentences);
use Lingua::LinkParser;
use Manager::Dialog qw(Message);
use String::Tokenizer;

my $parser = Lingua::LinkParser->new;
$parser->opts("max_parse_time",3);
my $tokenizer = String::Tokenizer->new;

my $ngrams = {};
my $max = {};
my $sum = {};
my $allsentences = {};

my $corpus = Corpus->new;
my $res = $corpus->ListRecent
  (Depth => 10000);

# need to implement loop detection (if a given word occurs more than 5 times, kill)
my $wordcount = {};

sub GenerateRandomWalk {
  # add a random walk generator to test
  # Message(Message => "Generate Random Walk");
  my @lead = ("START");
  my $total = {};
  my $nexttoken;
  my @sentence;
  while ($nexttoken ne "END" and $nexttoken ne "PREMATUREEND") {
    # print "--$nexttoken\n";
    if (scalar @lead == 1) {
      # get the next key and push it onto the lead
      my @l = keys %{$ngrams->{2}->{$lead[0]}};
      $nexttoken = "";
      my $count = 0;
      while (! $nexttoken and $count < 1000) {
	# choose a random token from the list
	my $possible = $l[rand(scalar @l)];
	if ($ngrams->{2}->{$lead[0]}->{$possible} > rand($max->{1}->{$lead[0]})) {
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
      my @l = keys %{$ngrams->{3}->{$lead[0]}->{$lead[1]}};
      $nexttoken = "";
      my $count = 0;
      while (! $nexttoken and $count < 1000) {
	# choose a random token from the list
	my $possible = $l[rand(scalar @l)];
	if ($ngrams->{3}->{$lead[0]}->{$lead[1]}->{$possible} > rand($max->{2}->{$lead[0]}->{$lead[1]})) {
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
      $wordcount->{$l}++;
      if ($wordcont->{$l} > 5) {
	return [];
      }
    }
  }
  push @sentence, ,@lead;
  return \@sentence;
}

# print "Done\n";
# print Dumper($ngrams);

sub AddNgrams {
  my %args = @_;
  my $ts = $args{Tokens};
  my $queues = [];
  foreach my $i (1..$args{N}) {
    my @tokens = @$ts;
    my @q;
    while (@tokens) {
      my $t = shift @tokens;
      # $t =~ s/\W+//g;
      $t =~ s/(\W)/\\$1/g;
      push @q, $t;
      if (scalar @q >= $i) {
	my $exp = "\$ngrams->{$i}->{\"".join("\"}->{\"",@q)."\"}++;";
	eval $exp;
	shift @q;
      }
    }
  }
}

sub TallyCounts {
  Message(Message => "Tally Counts");
  my %args = @_;
  foreach my $i (1..3) {
    foreach my $k1 (%{$ngrams->{$i}}) {
      if ($i <= 1) {
	$sum->{$i} += $ngrams->{$i}->{$k1};
	if ($ngrams->{$i}->{$k1} > $max->{$i}) {
	  $max->{$i} = $ngrams->{$i}->{$k1};
	}
      } elsif ($i <= 2) {
	foreach my $k2 (%{$ngrams->{$i}->{$k1}}) {
	  if ($i == 2) {
	    $sum->{$i}->{$k1} += $ngrams->{$i}->{$k1}->{$k2};
	    if ($ngrams->{$i}->{$k1}->{$k2} > $max->{$i}->{$k1}) {
	      $max->{$i}->{$k1} = $ngrams->{$i}->{$k1}->{$k2};
	    }
	  } elsif ($i == 3) {
	    foreach my $k3 (%{$ngrams->{$i}->{$k1}->{$k2}}) {
	      $sum->{$i}->{$k1}->{$k2} += $ngrams->{$i}->{$k1}->{$k2}->{$k3};
	      if ($ngrams->{$i}->{$k1}->{$k2}->{$k3} > $max->{$i}->{$k1}->{$k2}) {
		$max->{$i}->{$k1}->{$k2} = $ngrams->{$i}->{$k1}->{$k2}->{$k3};
	      }
	    }
	  }
	}
      }
    }
  }
}

sub GetTokens {
  # do a rather nice thing with punctuation, etc.
  my $e = shift;
  return split /\s+/, $e;
}

sub ProcessNGrams {
  Message(Message => "Process NGrams");
  my $i = 0;
  foreach my $entry (@$res) {
    my $sentences = get_sentences($entry);
    foreach my $sentence (@$sentences) {
      $allsentences->{$sentence} = 1;

      # get ngrams, first tokenize
      # $tokenizer->tokenize($entry);
      # my @tokens = $tokenizer->getTokens;
      my @tokens = GetTokens($entry);
      unshift @tokens, "START";
      push @tokens, "END";
      AddNgrams(N => 3,
		Tokens => \@tokens);
    }
    if (!($i % 100)) {
      # print "$i\n"
    }
    ++$i;
  }
  TallyCounts;
  Message(Message => "Generating random sanences ");
  while (1) {
    my $list = GenerateRandomWalk;
    if (@$list) {
      shift @$list;
      pop @$list;
      if (scalar @$list < 15) {
	my $sentence = join(" ",@$list);
	if (! exists $allsentences->{$sentence}) {
	  $allsentences->{$sentence} = 1;
	  my $ls = $parser->create_sentence
	    ($sentence);
	  my @l = $ls->linkages;
	  if (scalar @l > 2) {
	    print $sentence."\n";
	    # print "ACCEPTED: ".$sentence."\n";
	  } else {
	    # print ".\n";
	    # print "REJECTED: ".$sentence."\n";
	  }
	}
      }
    }
  }
}

ProcessNGrams;
