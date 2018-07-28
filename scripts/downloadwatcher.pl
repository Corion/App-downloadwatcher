#!perl
use strict;
use warnings;
use App::downloadwatcher;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.01';

GetOptions(
    'f|configfile=s' => \my $configfile,
    'n|dry-run'      => \my $dryrun,
    'verbose'        => \my $verbose,
) or pod2usage(2);

$configfile ||= './.downloadrc.yml';
$verbose ||= $dryrun;

my $watcher = App::downloadwatcher->new(
    config_file => $configfile,
    dryrun      => $dryrun,
    verbose     => $verbose,
);

$watcher->run( @ARGV );