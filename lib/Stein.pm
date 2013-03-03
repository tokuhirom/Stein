package Stein;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.01';

use Test::TCP;
use Furl 2.07;
use Plack::Request;
use HTTP::Request;
use File::Basename ();

use Mouse;

has psgi => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    trigger => sub {
        my ($self, $psgi) = @_;
        die "There is no file: $psgi" unless -e $psgi;
    },
);

has plack_env => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has child => (
    is => 'rw',
    lazy => 1,
    builder => '_build_child',
);

has timeout => (
    is => 'rw',
    default => sub { 7 },
);

has base_dir => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $carton_lock = find_file(File::Basename::dirname($self->psgi), 'carton.lock');
        if ($carton_lock) {
            File::Basename::dirname($carton_lock);
        } else {
            die "There is no carton.lock file around " . $self->psgi;
        }
    }
);

has agent => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;
        Furl->new(agent => "Stein/$VERSION", timeout => $self->timeout);
    },
);

no Mouse;

sub to_app {
    my ($self) = @_;

    sub {
        $self->handle_request(@_);
    };
}

sub handle_request {
    my ($self, $env) = @_;
    my $port = $self->child()->port;
    my $psgi_req = Plack::Request->new($env);
    # TODO: move to Furl::Request
    my $uri = $psgi_req->uri;
    $uri->host_port("127.0.0.1:$port");
    my $req = HTTP::Request->new(
        $psgi_req->method,
        $uri,
        $psgi_req->headers,
        $psgi_req->content,
    );
    my $res = $self->agent->request($req);
    return $res->to_psgi();
}

sub _build_child {
    my $self = shift;

    # use Proc::Guard + Net::EmptyPort
    return Test::TCP->new(
        code => sub {
            my $port = shift;
            my $base = $self->base_dir();
            exec $^X, '-Mlib::core::only', "-Mlib=$base/local/lib/perl5/", '--', "$base/local/bin/plackup", '--port', $port, '-E', $self->plack_env, $self->psgi;
        }
    );
}

sub find_file {
    my ($dir, $file) = @_;
    my %seen;
    while ( -d $dir ) {
        return undef if $seen{$dir}++;    # guard from deep recursion
        if ( -f "$dir/$file" ) {
            return "$dir/$file";
        }
        $dir = File::Basename::dirname($dir);
    }
    return undef;
}

1;
__END__

=encoding utf8

=head1 NAME

Stein - Gate for sub PSGI application

=head1 SYNOPSIS

    use Stein;

    builder {
        mount '/subapp' => Stein->new(
            psgi => 'path/to/app.psgi',
            plack_env => 'development',
        )->to_app();
    };

=head1 DESCRIPTION

Stein is sub psgi application runner.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 MOTIVATION

I want to run sub application in child process, mount on main psgi application process.

=head1 USE CASE

I wrote a psgi application to manage database, like phpmyadmin. It depend to some CPAN modules.

=head1 CONSTRUCTOR ARGUMENTS

=over 4

=item psgi: Str

Path to psgi application file.

I<Required>

=item plack_env: Str

PLACK_ENV for child process.

I<Requred>

=item timeout: Int

Furl timeout in seconds.

I<Optional>

I<Default Value>: 7 seconds.

=item agent : Furl

I<Optional>

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Plack>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
