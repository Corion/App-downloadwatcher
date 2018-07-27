#!perl -w
use strict;
use App::downloadwatcher;
use Getopt::Long;
use Pod::Usage;

GetOptions(
    'f|configfile=s' => \my $configfile,
) or pod2usage(2);

$configfile ||= './.downloadrc.yml';

my $watcher = App::downloadwatcher->new(
    config_file => $configfile,
);
$watcher->run;