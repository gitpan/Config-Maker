package Config::Maker::Driver;

use utf8;
use warnings;
use strict;

use Carp;
use Parse::RecDescent;

use Config::Maker;
use Config::Maker::Encode;
use Config::Maker::Option;
use Config::Maker::Path;

my $parser = $Config::Maker::parser;

sub apply {
    for my $e (@_) {
	if(ref $e eq 'CODE') {
	    $e->();
	} elsif(ref $e) {
	    $e->do();
	} else {
	    print $e;
	}
    }
}

sub process {
    my ($class, $file, $config, $outfh, $outenc) = @_;
    my ($fh, $text);
    my $enc = 'system';

    open($fh, '<', $file)
	or croak "Failed to open $file: $!";
    {
	local $/;
	$text = <$fh>;
    }
    close $fh;

    if((substr($text, 0, 250) =~ /\[#[^#]*$Config::Maker::fenc([[:alnum:]_-]+)/) ||
       (substr($text, -250)   =~ /\[#[^#]*$Config::Maker::fenc([[:alnum:]_-]+)/)) {
       $enc = $1;
    }
    $text = decode($enc, $text);
    $outenc ||= $enc;
    encmode($outfh, $outenc);

    croak "Invalid config!"
	unless UNIVERSAL::isa($config, 'Config::Maker::Config');

    local $Config::Maker::Eval::config = $config;
    local $_ = $config->{root};

    LOG("Processing template $file encoded $enc with output in $outenc");
    my $out = $parser->template($text);
    croak "Template file $file contained errors"
	unless defined $out;

    my $old = select;
    select $outfh;
    eval { apply(@$out); };
    select $old;
    die $@ if $@;
}

1;

__END__

=head1 NAME

Config::Maker::Driver - FIXME

=head1 SYNOPSIS

  use Config::Maker::Driver
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
# arch-tag: 6a447a76-79d0-4b62-a624-f3e9e615f261
