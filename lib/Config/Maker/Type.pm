package Config::Maker::Type;

use utf8;
use warnings;
use strict;

use Carp;
use Config::Maker;
use Config::Maker::Path;

require Config::Maker::Option;
our @CARP_NOT = qw(Config::Maker::Option);

use overload
    'cmp' => \&Config::Maker::truecmp,
    '<=>' => \&Config::Maker::truecmp,
    '""' => 'name',
    fallback => 1;

our $root;
our $repository;
our %checks;

# Get top-level context ('/' special type):
sub root {
    $root;
}

# Get repository context ('*' special type). The repository is a special type
# where types for reuse are stored:
sub repository {
    $repository;
}

# Get a type from a context. Context is just a type currently being
# built:
sub get {
    my ($ctx, $name) = @_;
    
    croak "No type $name in $ctx" unless $ctx->{children}{$name};
    return $ctx->{children}{$name};
}

# Build an Option using given arguments:
sub instantiate {
    my ($self, $args) = @_;

    ref $args eq 'HASH' or confess "Not a hash reference!";
    Config::Maker::Option->new(-type => $self, %$args);
}

# Get arguments for syntactic rule for arguments.
sub body {
    my ($self) = @_;
    @{$self->{format}};
}

# Get the name of the option type.
sub name {
    my ($self) = @_;
    $self->{name};
}

# Build a new type...
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

sub _type {
    my ($type) = @_;
    confess "_type($type)" unless $type;
    return $type if UNIVERSAL::isa($type, __PACKAGE__);
    return __PACKAGE__->repository->get($type);
}

sub _path {
    return Config::Maker::Path->make(@_);
}

sub _check {
    my ($check, $path) = @_;
    croak "No check $check" unless $checks{$check};
    $check = $checks{$check};
    $path = _path($path);
    return sub {
	$check->($_[0], $path);
    }
}

sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my %type = (
	name => _ref(%args, 'name'),
	format => _ref(%args, 'format'),
	children => {},
	checks => [],
	actions => _ref(%args, 'actions', []),
    );
    my $self = bless \%type, $class;

    # Children...
    $self->add(@{_ref %args, 'children', []});

    # Aditional checks...
    $self->addchecks(@{_ref %args, 'checks', []});

    $self->addto(@{_ref %args, 'contexts', [any => '*']});

    croak "Unknown arguments: " . join(', ', keys %args)
	if %args;
    return $self;
}

sub add {
    my $self = shift;
    my @children = @_;
    while(my ($spec, $type) = splice(@children, 0, 2)) {
	$type = _type($type);
	next if $self->{children}->{$type} eq $type;
	croak "Different type named $type already added to $self"
	    if exists $self->{children}->{$type};
	$self->{children}->{$type->name} = $type;
	push @{$self->{checks}}, _check($spec, "$type");
    }
}

sub addto {
    my $self = shift;
    my @contexts = @_;
    while(my ($spec, $ctx) = splice(@contexts, 0, 2)) {
	_type($ctx)->add($spec, $self);
    }
}

sub addchecks {
    my $self = shift;
    my @checks = @_;
    while(my ($spec, $path) = splice(@checks, 0, 2)) {
	push @{$self->{checks}}, _check($spec, $path);
    }
}

# Initialize:

# format not used for the magic items, but is mandatory...
$repository = __PACKAGE__->new(
    name => '*',
    format => [],
    contexts => [], # self-reference otherwise...
);

$repository->add(any => $repository);
# Phew, and now _type should work...

$root = __PACKAGE__->new(
    name => '/',
    format => [],
); # Default context (in repository only) should work here...

# Checking functions:

sub _findtimes {
    confess "$_[1] can't ->find" unless UNIVERSAL::can($_[1], 'find');
    my $r = $_[1]->find($_[0]);
    croak "Too few $_[1] in " . $_[0]->id if @$r < $_[2];
    return 1 if @_ == 3;
    croak "Too many $_[1] in " . $_[0]->id if @$r > $_[3];
    return 1;
}

BEGIN { # Constants must be done early enough...
    %checks = (
	none => sub { _findtimes(@_, 0,0); },
	opt =>  sub { _findtimes(@_,0,1); },
	one =>  sub { _findtimes(@_,1,1); },
	mand => sub { _findtimes(@_,1); },
	any => sub { 1; },
    );
}

1;

__END__

=head1 NAME

Config::Maker::Type - FIXME

=head1 SYNOPSIS

  use Config::Maker::Type
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
# arch-tag: f61c8e42-7bad-4720-b65a-350808fc6bb9
