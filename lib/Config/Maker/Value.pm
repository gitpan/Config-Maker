package Config::Maker::Value;

use utf8;
use warnings;
use strict;

use Carp;

package Config::Maker::Value::List;
use vars qw(@ISA); @ISA = qw(Config::Maker::Value);

use overload
    '""' => sub { '[' . join(', ', @{$_[0]}) . ']' },
    fallback => 1;

sub new {
    my ($class, $aref) = @_;
    bless $aref, $class;
}

package Config::Maker::Value;

1;

__END__

=head1 NAME

Config::Maker::Value - FIXME

=head1 SYNOPSIS

  use Config::Maker::Value
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
# arch-tag: 7d833b6a-26a1-4eac-b2a7-fb770466a080
