package Config::Maker::Encode;

use utf8;
use warnings;
use strict;

use Carp;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(encode decode encmode);

sub encode($$;$);
sub decode($$;$);
sub encmode(*$);

sub _encode_only_system($$;$) {
    my ($enc, $text, $check) = @_;
    unless($enc eq 'system') {
	if($check == 1) {
	    croak "Encoding not available. Can't convert encoding $enc";
	} else {
	    carp "Encoding not available. Can't convert encoding $enc";
	}
    }
    return $text;
}

sub _binmode_only_system(*$) {
    my ($handle, $enc) = @_;
    unless($enc eq 'system') {
	carp "Encoding not available. Can't set encoding to $enc";
    }
}

sub _binmode_encoding(*$) {
    my ($handle, $enc) = @_;
    binmode $handle, ":encoding($enc)";
}

eval {
    require I18N::Langinfo;
    require Encode;
    require Encode::Alias;
    require PerlIO::encoding;
    $::ENCODING = I18N::Langinfo::langinfo(&I18N::Langinfo::CODESET);
    if(!$::ENCODING) {
	$::ENCODING_LOG = "Can't get your locale encoding! Assuming ASCII.";
	Encode::find_encoding($::ENCODING = 'ascii')
	    or die "Can't get ascii codec!";
    } elsif(!Encode::find_encoding($::ENCODING)) {
	$::ENCODING_LOG = "Your locale encoding `$::ENCODING' it's not supported by Encode!";
	Encode::find_encoding($::ENCODING = 'ascii')
	    or die "Can't get ascii codec!";
    }
    Encode::Alias::define_alias('system' => $::ENCODING);
};

if($@) { # Encoding stuff not available!
    undef $::ENCODING;
    *encode = \&_encode_only_system;
    *decode = \&_encode_only_system;
    *encmode = \&_binmode_only_system;
} else { # Wow! Encoding is available!
    *encode = \&Encode::encode;
    *decode = \&Encode::decode;
    *encmode = \&_binmode_encoding;
    binmode STDERR, ':encoding(system)';
}

1;

__END__

=head1 NAME

Config::Maker::Encode - FIXME

=head1 SYNOPSIS

  use Config::Maker::Encode
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
# arch-tag: 350a53f2-ce83-465a-9861-b4542b792033
