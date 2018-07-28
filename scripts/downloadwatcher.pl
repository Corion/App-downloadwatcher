#!perl
use strict;
use warnings;
use App::downloadwatcher;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.01';

=head1 NAME

downloadwatcher.pl - watch incoming files in a folder and execute actions on them

=head1 SYNOPSIS

    downloadwatcher.pl

=head1 OPTIONS

=over 4

=item B<f|configfile>

Set the config file.

The default is C<.downloadrc> in the current directory

=item B<n|dry-run>

Only output diagnostics, don't execute handlers.

=item B<verbose>

Output matched and missed rules to the console

=back

=cut

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