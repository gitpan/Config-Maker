package Config::Maker::Path::AnyPath;

use utf8;
use warnings;
use strict;

use Carp;
use Config::Maker::Path;
our @ISA = qw(Config::Maker::Path);

sub new {
    shift->bhash([qw/-tail/], @_);
}

sub match {
    my ($self, $from) = @_;

    ($from, map { $self->match($_) } @{$from->{-children}});
}

sub text { '**' }

1;

__END__

=head1 NAME

Config::Maker::Path::AnyPath - FIXME

=head1 SYNOPSIS

  use Config::Maker::Path::AnyPath
FIXME

=head1 DESCRIPTION

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: cbf3e128-9aee-459d-a6cc-e05e1d52bff3
