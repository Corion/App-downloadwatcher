#!perl
use strict;
use warnings;
use App::downloadwatcher;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.01';

GetOptions(
    'f|configfile=s' => \my $configfile,
) or pod2usage(2);

$configfile ||= './.downloadrc.yml';

my $watcher = App::downloadwatcher->new(
    config_file => $configfile,
);
$watcher->run;