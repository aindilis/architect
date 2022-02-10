#!/usr/bin/perl -w

# an attempt to build a controlled english using ngrams as a starting point

use Corpus;
use System::LinkParser;

use Data::Dumper;
use Lingua::EN::Sentence qw(get_sentences);
use String::Tokenizer;

my $parser = System::LinkParser->new;
# $parser->opts("max_parse_time",3);
my $tokenizer = String::Tokenizer->new;

my ($ngrams,$max,$sum) = ({},{},{});

my $allsentences = {};
my $corpus = Corpus->new;
my $res = $corpus->ListRecent
  (Depth => 30000);
foreach my $sentence (@$res) {
  $allsentences->{$sentence} = 1;
}

sub GenerateRandomWalk {
  # add a random walk generator to test
  my @lead = ("START");
  my $total = {};
  my $nexttoken;
  my @sentence;
  while ($nexttoken ne "END" and $nexttoken ne "PREMATUREEND") {
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
      $t =~ s/\W+//g;
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

sub ProcessNGrams {
  my $i = 0;
  foreach my $entry (@$res) {
    my $sentences = get_sentences($entry);
    foreach my $sentence (@$sentences) {
      # get ngrams, first tokenize
      $tokenizer->tokenize($entry);
      my @tokens = $tokenizer->getTokens;
      unshift @tokens, "START";
      push @tokens, "END";
      AddNgrams(N => 3,
		Tokens => \@tokens);
    }
    if (!($i % 100)) {
      print "$i\n"
    }
    ++$i;
  }
  TallyCounts;
  while (1) {
    my $list = GenerateRandomWalk;
    shift @$list;
    pop @$list;
    my $sentence = join(" ",@$list);
    if (! exists $allsentences->{$sentence}) {
      $allsentences->{$sentence} = 1;
      if ($parser->CheckSentence
	  (Sentence => $sentence)) {
	print $sentence."\n";
	# print "ACCEPTED: ".$sentence."\n";
      } else {
	# print ".\n";
	# print "REJECTED: ".$sentence."\n";
      }
    }
  }
}

ProcessNGrams;
