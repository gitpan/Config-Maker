package Config::Maker::Option;

use utf8;
use warnings;
use strict;

use Carp;

use Config::Maker;
use Config::Maker::Type;
use Config::Maker::Path;

use overload
    'cmp' => \&Config::Maker::truecmp,
    '<=>' => \&Config::Maker::truecmp,
    '""' => sub { $_[0]->{-value}; },
    '/' => sub { 
	croak "Can't \"divide by\" option" if $_[2];
	$_[0]->get($_[1]);
    },
    '&{}' => sub {
	my $self = $_[0];
	sub { $self->get(@_); };
    },
    fallback => 1;

sub _ref(\%$;$) {
    my ($hash, $key, $default) = @_;
    if(exists $hash->{$key}) {
	my $rv = $hash->{$key};
	delete $hash->{$key};
	return $rv;
    } elsif(@_ == 3) {
	return $default;
    } else {
	croak "Mandatory argument $key not specified";
    }
}

sub new {
    my ($class, %args) = @_;
    my $type = _ref(%args, '-type');

    my $self = {
	-type => $type,
	-value => _ref(%args, '-value', ''),
	-children => _ref(%args, '-children', []),
    };
    croak "Unknown arguments: " . join(', ', keys %args)
	if %args;
    bless $self, $class;

    foreach my $child (@{$self->{-children}}) {
	$child->{-parent} = $self;
    }

    foreach my $check (@{$type->{checks}}) {
	&$check($self);
    }

    foreach my $action (@{$type->{actions}}) {
	&$action($self);
    }

    DBG("Instantiated $type");
    $self;
}

sub get {
    my ($self, $path) = @_;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($self);
    return wantarray ? @$res : $res->[0];
}

sub get1 {
    my ($self, $path) = @_;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($self);
    Carp::croak "$path should have exactly one result" if $#$res;
    return $res->[0];
}

sub getval {
    my ($self, $path, $default) = @_;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($self);
    Carp::croak "$path should have at most one result" if @$res > 1;
    @$res ? $res->[0]->{-value} : $default;
}

sub type {
    $_[0]->{-type};
}

sub id {
    "$_[0]->{-type}:$_[0]->{-value}";
}

1;

__END__

=head1 NAME

Config::Maker::Option - FIXME

=head1 SYNOPSIS

  use Config::Maker::Option
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
# arch-tag: b5642443-d4c6-4cb5-9420-cf16eca27cac
