package Nephia::Plugin::SocketIO;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use PocketIO;
use Plack::Builder;
use Nephia::Plugin::SocketIO::Assets;
use Data::Dumper::Concise;

our $VERSION = "0.01";

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    $self->app->builder_chain->append('SocketIO' => $class->can('_wrap_app'));
    return $self;
}

sub exports { qw/socketio/ }

sub socketio {
    my ($self, $context) = @_;
    return sub ($&) {
        my ($event, $code) = @_;
        $self->{events}{$event} = $code;
    };
}

sub _wrap_app {
warn Dumper({ wrap_app => [@_] });
    my $app = shift;
    builder {
        mount '/socket.io.js' => sub {
            [200, ['Content-Type' => 'text/javascript'], [Nephia::Plugin::SocketIO::Assets->get('socket.io.js')]];
        };
        mount '/socket.io' => PocketIO->new(handler => sub {
            my $socket = shift;
            for my $event (keys %{$app->{events}}) {
                $socket->on($event => $app->{events}{$event});
            }
            $socket->send({buffer => []});
        });
        mount '/' => builder {
            enable 'SimpleContentFilter', filter => sub{
                s|(</body>)|$1\n<script type="text/javascript" src="/socket.io.js"></script>|i;
            };
            $app;
        };
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::SocketIO - It's new $module

=head1 SYNOPSIS

    use Nephia::Plugin::SocketIO;

=head1 DESCRIPTION

Nephia::Plugin::SocketIO is ...

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut
