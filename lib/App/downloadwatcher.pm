package App::downloadwatcher;
use strict;
use warnings;
use Moo;
use Path::Class;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use YAML 'LoadFile';
use File::HomeDir;
use Filesys::Notify::Simple;

our $VERSION = '0.01';

=head1 NAME

App::downloadwatcher - launch actions on downloaded files

=cut

has 'config_file' => (
    is => 'ro',
);

has 'config' => (
    is => 'rw',
);

has 'watcher' => (
    is => 'rw',
    default => \&_build_watcher,
);

has 'dryrun' => (
    is => 'ro',
);

has 'verbose' => (
    is => 'ro',
);

has 'directories' => (
    is => 'rw',
    default => \&_build_directories,
);

has 'actions' => (
    is => 'rw',
    default => sub { [] },
);

sub update_config( $self, $config = $self->read_config()) {
    # Replace our actions
    $self->actions( delete $config->{actions} );

    # Check if we need a new watcher:
    my $current = join "\0", grep { $_ ne $self->config_file } @{ $self->directories };
    my $next = join "\0", @{ $config->{directories} || $self->directories };
    if( $current ne $next ) {
        $self->directories( delete $config->{directories} );
        $self->watcher( $self->_build_watcher );
    };
}

sub alternation( $glob_expr ) {
    $glob_expr =~ s!,!|!g;
    $glob_expr
}

# This should be a proper parser instead of hacky regexes!
sub glob_to_regex( $glob ) {
    my %map = (
        '*' => '.*',
        '?' => '.',
        '.' => '\\.',
        '(' => '\\(',
        ')' => '\\)',
    );

    $glob =~ s!([*?.()])!$map{ $1 }!ge;
    $glob =~ s!\{([^{}]+)}!alternation($1)!ge;
    qr/\A(?:$glob)\z/
}

sub read_config( $self, $config_file=$self->config_file ) {
    my $config = LoadFile( $config_file );

    # Convert everything to arrays of regexes:

    for my $action (@{ $config->{ actions }}) {
        if( $action->{ file_regex } and ! ref $action->{ file_regex }) {
            $action->{ file_regex } = [ $action->{ file_regex } ]
        };

        if( $action->{ file_glob } and ! ref $action->{ file_glob}) {
            $action->{ file_glob} = [ $action->{ file_glob } ]
        };

        if( $action->{ file_glob } ) {
            for my $glob (@{ $action->{ file_glob }}) {
                $glob = glob_to_regex($glob);
            };
        };

        #if( $action->{ file_content }) {
        #};
    };

    $config
}

sub _build_watcher( $self, $directories = $self->directories ) {
    my $dir = [@$directories];
    #if( my $cfg = $self->config_file ) {
    #    push @$dir, file($cfg)->absolute('.')->parent
    #};
    #warn "Watching @$dir";
    Filesys::Notify::Simple->new($dir);
}

sub _build_directories( $self ) {
    [
        grep { -d "$_" }
        map  { "$_/Downloads" }
        grep { defined($_) }
        File::HomeDir->my_home
    ]
}

sub run( $self, @files ) {
    $self->update_config;
    if( @files ) {
        for my $file (@files) {
            $self->file_changed( $file );
        };
    } else {
        while( 1 ) {
            $self->watcher->wait(sub( @events ) {
                #my $config_file = file($self->config_file)->absolute('.');
                for my $event (@events) {
                    #if( $event->{path} eq $config_file ) {
                    #    warn "Reloading config";
                    #    $self->update_config();
                    #} else {
                        # We only care for created files, not for deleted files:
                        if( -f $event->{path} ) {
                            $self->file_changed( $event->{path})
                        }
                    #}
                }
            })
        }
    };
}

sub regex_match( $file, $list ) {
    for my $item (@$list) {
        #warn "$file =~ /$item/ :" . ( $file =~ /$item/ ? 1 : 0);
        return 1 if $file =~ /$item/
    }
}

sub find_actions( $self, $file ) {
    my @matches =
    grep {
           regex_match( $file, $_->{file_regex} )
        or regex_match( $file, $_->{file_glob} )
    } @{ $self->actions };

    @matches
};

sub file_changed( $self, $file ) {
    my $name = file( $file )->basename;
    my @actions = $self->find_actions( $name );
    for my $action (@actions) {
        if( $action->{handler}) {
            my $cmd = $action->{handler};
            $cmd =~ s!\$file!$file!;
            if( $self->verbose ) {
                print "Running $cmd\n";
            };
            if( ! $self->dryrun ) {
                system( $cmd );
                return;
            };
        };
    };
    if( $self->verbose ) {
        print "No rule matches for '$file'\n";
    };
}

1;