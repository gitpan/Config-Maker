package Config::Maker::Metaconfig;

use utf8;
use warnings;
use strict;

use Carp;
use File::Spec;
use File::Basename;
use File::Temp qw(tempfile);

use Config::Maker;
use Config::Maker::Type;
use Config::Maker::Config;
use Config::Maker::Driver;

sub type {
    Config::Maker::Type->new(@_);
}

# Top-level element "search-path"

my $search = type(
    name => 'search-path',
    format => [simple => [zero_list => 'string']],
    contexts => [opt => '/'],
);

# Top-level element "output-dir"

my $output = type(
    name => 'output-dir',
    format => [simple => ['string']],
    contexts => [opt => '/'],
);

# Top-level element "config"

my $config = type(
    name => 'config',
    format => ['named_group' => ['string']],
    contexts => [any => '/'],
);

# The template element

my $template = type(
    name => 'template',
    format => ['anon_group'],
    contexts => [any => $config],
);

my $src = type(
    name => 'src',
    format => [simple => ['string']],
    contexts => [one => $template],
);

my $out = type(
    name => 'out',
    format => [simple => ['string']],
    contexts => [opt => $template],
);

my $command = type(
    name => 'command',
    format => [simple => ['string']],
    contexts => [opt => $template],
);
$template->addchecks(mand => 'out|command');

my $enc = type(
    name => 'enc',
    format => [simple => ['string']],
    contexts => [opt => $template],
);

sub _find {
    my ($file, @path) = @_;
    if(File::Spec->file_name_is_absolute($file)) {
	return $file;
    } else {
	for(@path) {
	    my $f = File::Spec->rel2abs($file, $_);
	    DBG "Trying: $f";
	    return $f if -r $f;
	}
	local $" = ', ';
	croak "Can't find $file in @path";
    }
}

sub _qual($$) {
    my ($file, $dir) = @_;
    return unless $file;
    if(File::Spec->file_name_is_absolute($file)) {
	return $file;
    } else {
	return File::Spec->rel2abs($file, $dir);
    }
}

sub _get_cfg {
    Config::Maker::Config->new(_find(@_));
}

our @unlink;

sub do {
    my ($class, $metaname, $noinst) = @_;
    
    my $meta = Config::Maker::Config->new($metaname)->{root};

    my @path = @{$meta->getval('search-path', ['/etc/'])};
    { local $"=', '; DBG "Search path: @path"; }

    my $outdir = $meta->getval('output-dir', '/etc/');
    DBG "Output-dir: $outdir";

    # For each config file and each template...
    for my $cfg ($meta->get('config')) {
	LOG "Processing config $cfg";
	my $conf = _get_cfg($cfg->{-value}, @path);
	for my $tmpl ($cfg->get('template')) {
	    my ($fh, $name);
	    $name = $tmpl->get('out');
	    if($name) {
		$name = _qual($name, $outdir);
		($fh, $name) = tempfile(
		    basename($name, qr/\..*/) . ".cmXXXXXX",
		    DIR => dirname($name));
	    } else {
		($fh, $name) = tempfile(
		    basename($tmpl->get1('src'), qr/\..*/) . ".cmXXXXXXXX",
		    DIR => File::Spec->tmpdir);
	    }
	    DBG "Using $name as temporary for $tmpl output";
	    push @unlink, $name;
	    Config::Maker::Driver->process(
		_find($tmpl->get1('src'), @path),
		$conf, $fh, $tmpl->get('enc'),
	    );
	    $tmpl->{-data} = [$fh, $name];
	    close $fh;
	}
    }

    # Now, for each template install the temporary file...
    if($noinst) {
	for my $tmpl ($meta->get('config/template')) {
	    my ($fh, $name) = @{$tmpl->{-data}};
	    @unlink = grep { $_ ne $name } @unlink;
	    my $dest;
	    if($dest = _qual($tmpl->get('out'), $outdir)) {
		print STDOUT "Install: $name $dest\n";
	    }
	    if($dest = $tmpl->get('command')) {
		print STDOUT "Invoke: $dest < $name\n";
	    }
	}
    } else {
	for my $tmpl ($meta->get('config/template')) {
	    my ($fh, $name) = @{$tmpl->{-data}};
	    my $dest;
	    if($dest = _qual($tmpl->get('out'), $outdir)) {
		LOG "Installing $dest";
		rename $name, $dest
		    or croak "Failed to install $dest: $!";
		@unlink = grep { $_ ne $name } @unlink;
		$name = $dest;
	    }
	    if($dest = $tmpl->get('command')) {
		LOG "Invoking $dest";
		my $pid = fork;
		croak "Failed to fork: $!" unless defined $pid;
		unless($pid) { # The child...
		    open STDIN, '<', $name;
		    exec $dest;
		    die "Failed to exec $dest: $!";
		}
		# The parent...
		waitpid($pid, 0) != -1
		    or croak "Wait failed: $!";
		croak "Command failed: $?" if "$?";
	    }
	}
    }
    # should be done...(!)
}

END {
    foreach(@unlink) {
	unlink $_ or warn "Unlinking `$_' failed: $!";
    }
}

1;

__END__

=head1 NAME

Config::Maker::Metaconfig - Definies and processes the metaconfig directives.

=head1 SYNOPSIS

  use Config::Maker

  Config::Maker::Metaconfig->do($metafile);

=head1 DESCRIPTION

This module defines types for the C<config> directive and their subdirectives,
that are used in the metaconfig. It has only one public method, C<do>, which
loads metaconfig from a file.

Note: The metaconfig can only be read from a file.

See L<configit(1)> for description of metaconfig directives.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm), Config::Maker::Schema(3pm).

=cut
# arch-tag: a49cb2b5-850a-4724-bd4f-707f66c90277
