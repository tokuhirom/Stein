# NAME

Stein - Gate for sub PSGI application

# SYNOPSIS

    use Stein;

    builder {
        mount '/subapp' => Stein->new(
            psgi => 'path/to/app.psgi',
            plack_env => 'development',
        )->to_app();
    };

# DESCRIPTION

Stein is sub psgi application runner.

__THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE__.

# MOTIVATION

I want to run sub application in child process, mount on main psgi application process.

# USE CASE

I wrote a psgi application to manage database, like phpmyadmin. It depend to some CPAN modules.

# CONSTRUCTOR ARGUMENTS

- psgi: Str

    Path to psgi application file.

    _Required_

- plack\_env: Str

    PLACK\_ENV for child process.

    _Requred_

- timeout: Int

    Furl timeout in seconds.

    _Optional_

    _Default Value_: 7 seconds.

- agent : Furl

    _Optional_

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[Plack](http://search.cpan.org/perldoc?Plack)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
