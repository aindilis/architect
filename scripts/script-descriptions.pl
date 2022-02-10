#!/usr/bin/perl -w

use BOSS::ICodebase qw(GetSystems);
use BOSS::Script;

use Data::Dumper;
use Lingua::EN::Sentence qw(get_sentences);
use Lingua::LinkParser;

# my $parser = Lingua::LinkParser->new;

my @process;
my $systems = GetSystems;
foreach my $sys (keys %$systems) {
  my $sdir = $systems->{$sys}."/scripts";
  if (-d $sdir) {
    foreach my $s (split /\n/, `ls "$sdir"`) {
      if (-f "$sdir/$s" and $s !~ /[\~\#]$/) {
	my $f = "$sdir/$s";
	my $res = `file "$f"`;
	if ($res =~ /perl script/) {
	  push @process, $f;
	  print "$f\n";
	}
      }
    }
  }
}
my $sdir = "/usr/local/share/perl/5.8.3";
foreach my $item (split /\n/, `ls "$sdir"`) {
  if (-d "$sdir/$item") {
    foreach my $s (split /\n/, `find "$sdir/$item" -follow`) {
      if (-f "$s" and $s =~ /\.pm$/i) {
	push @process, "$s";
	print "$s\n";
      }
    }
  } elsif (-f "$sdir/$item") {
    push @process, "$sdir/$item";
    print "$sdir/$item\n";
  }
}


my $descriptions = {};
foreach my $f (@process) {
  $descriptions->{$f} = ProcessCommentsInFile
    (File => $f);
}

my $OUT;
open(OUT,">/var/lib/myfrdcsa/codebases/internal/architect/data/descriptions.pl") or die "cannot\n";
print OUT Dumper($descriptions);
close(OUT);

sub ProcessCommentsInFile {
  my (%args) = @_;
  my $f = $args{File};
  if (-f $f) {
    my $c = `cat "$f"`;
    # get chunks
    my @res;
    my $state = 0;
    foreach my $l (split /\n/,$c) {
      if ($state == 0 and ($l =~ /\#\!\/usr/ or $l =~ /package/)) {
	$state = 1;
      } elsif ($state == 1) {
	if ($l =~ /^\s*$/) {

	} elsif ($l =~ /^\s*\#\s*(.*)$/) {
	  push @res, $1;
	} else {
	  $state = 2;
	}
      }
    }
    my $txt = join("\n",@res);
    @res = ();
    my $sentences = get_sentences($txt);
    foreach my $sentence (@$sentences) {
      $sentence =~ s/\n/ /g;
      $sentence =~ s/\s+/ /g;
      $sentence =~ s/\b(\w)/\U$1/;
      # if it doesn't have a punctionation mark at the end
      if (0) {
	if ($sentence !~ /[\:\;\!\?\.]$/) {
	  my $ls = $parser->create_sentence($sentence);
	  my @linkages = $ls->linkages;
	  if (! scalar @linkages) {
	    $sentence .= ";";
	  } else {
	    if (0) {
	      # if it is a question --
	      # $sentence .= "?";
	    } else {
	      $sentence .= ".";
	    }
	  }
	}
      }
      push @res, $sentence;
    }
    return \@res;
  }
}
