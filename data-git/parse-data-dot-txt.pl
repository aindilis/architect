#!/usr/bin/perl -w

use KBS2::ImportExport;
use PerlLib::SwissArmyKnife;

use Text::Capitalize;

my $c = read_file('/var/lib/myfrdcsa/codebases/internal/architect/data-git/data.txt');
my $mode = 'start';
my $submode = 'start';
my $keys = {};
my @assertions;
foreach my $line (split /\n/, $c) {
  $line =~ s/^\s*//;
  $line =~ s/\s*$//;

  if ($line =~ /^(EXISTING CAPABILITIES|DESIRED CAPABILITIES):$/) {
    $mode = $line;
  } elsif ($line =~ /^(KEY:|Misc|Natural Language Processing:|Semantic Annotation \(OpenCalais\)|HTML Processing|INFORMATION EXTRACTION|AI\/Knowledge Representation:|Studying|Humanitarian\/Life Support)$/) {
    $submode = $line;
  } else {
    if ($mode eq 'EXISTING CAPABILITIES:') {
      if ($submode eq 'KEY:') {
	if ($line =~ /\((.)(.+?)\) -> (.+?)$/) {
	  $keys->{$1} = {
			 2 => $2,
			 3 => $3,
			};
	}
      } else {
	if ($line =~ /^([^\(]+)\s+\((.+?)\)$/) {
	  my $capability = $1;
	  my $systems = $2;
	  foreach my $systemfull (split /[\/\|]/, $systems) {
	    if ($systemfull =~ /^(\W*)(.+?)$/) {
	      my $mykeys = $1;
	      my $system = $2;
	      push @assertions, ['hasCapability',mpa($system),mpa($capability)];
	      foreach my $key (split //, $mykeys) {
		push @assertions,
		  [mpa($keys->{$key}->{3}),mpa($system)];
	      }
	    }
	  }
	}
      }
    }
  }
}

my $ie = KBS2::ImportExport->new();
my @output;
foreach my $assertion (@assertions) {
  # print Dumper(\@assertions);
  # print Dumper($keys);
  my $res = $ie->Convert
    (
     Input => [$assertion],
     InputType => 'Interlingua',
     OutputType => 'Prolog',
    );
  if ($res->{Success}) {
    push @output, $res->{Output};
  }
}
print join('',@output)."\n";

sub mpa {
  my ($item) = @_;
  MakePrologAtom(Input => $item);
}

sub MakePrologAtom {
  my (%args) = @_;
  my @i = split /\s+/, $args{Input};
  my @letters = split //, shift @i;
  my $firstletter = shift @letters;
  return lc($firstletter).join('',@letters).join('',map {capitalize($_)} @i);
}
