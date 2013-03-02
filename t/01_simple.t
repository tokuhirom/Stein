use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;
use Stein;
use Plack::Builder;

my $app = builder {
    mount '/hello', Stein->new(
        psgi => 't/psgi/hello.psgi',
    )->to_app();
};

test_psgi(app => $app, client => sub {
    my $cb = shift;
    my $req = HTTP::Request->new(GET => "http://localhost/hello");
    my $res = $cb->($req);
    like $res->content, qr/Hello World/;
});


done_testing;

