package Stein;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.01';

use Test::TCP;
use Furl 2.07;
use Plack::Request;
use HTTP::Request;

use Mouse;

has psgi => (
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

    return Test::TCP->new(
        code => sub {
            my $port = shift;
            require Plack::Loader;
            require Plack::Util;
            my $app = Plack::Util::load_psgi($self->psgi);
            Plack::Loader->auto(port => $port)->run($app);
        }
    );
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
