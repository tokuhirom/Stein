requires 'Furl', '2.07';
requires 'HTTP::Request';
requires 'Mouse';
requires 'Net::EmptyPort';
requires 'Plack::Request';
requires 'Proc::Guard';
requires 'Test::TCP';
requires 'lib::core::only';
requires 'parent';
requires 'perl', '5.008005';

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
};
