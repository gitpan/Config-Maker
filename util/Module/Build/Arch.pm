package Module::Build::Arch;

use utf8;
use warnings;
use strict;

use Carp;

use base 'Module::Build';

sub slurp {
    my ($file) = @_;
    local *FH;
    local $/;
    open FH, '<', $file or die "Can't open $file: $!";
    my $rv = <FH>;
    chomp $rv;
    close FH;
    return $rv;
}

sub ACTION_manifest {
    my ($self) = @_;
    local *INVENTORY;
    local *MANIFEST;
    open INVENTORY, 'tla inventory --source |' or die "Can't run tla: $!";
    open MANIFEST, '>MANIFEST' or die "Can't write MANIFEST: $!";
    print MANIFEST <<'ENDMANIFEST';
META.yml
README
Makefile.PL
MANIFEST
ChangeLog
ENDMANIFEST
    print MANIFEST $_ for(<INVENTORY>);
    close INVENTORY;
    close MANIFEST;
}

sub ACTION_changelog {
    system('tla changelog > ChangeLog') == 0 or die "Running tla failed (status $?)";
}

sub do_create_readme {
    my $self = shift;
    require Pod::Text;
    my $parser = Pod::Text->new;
    $parser->parse_from_file('README.pod', 'README', @_);
}

sub dist_version {
    my $self = shift;
    my $version = $self->SUPER::dist_version(@_);

    if($version eq 'tree-version') { # Going to fix-up version...
	my $text = qr/(?:-?[\w,%])+/;
	my $patch = qr/(?:base|patch|version|versionfix)/;
	my $treever = qx(tla logs -f -r | head -n 1);
	die "Running tla failed (status $?)" if $?;

	my ($ARCHIVE, $CATEGORY, $BRANCH, $VERSION, $REVISION)
	    = $treever =~ m{^   (.*)
			    /   ($text)
			    --  (?:($text)--)?
				([\d.]+)
			    --  $patch-([\d.]+)
			    $}x or die "Bad tree revision: `$treever'";
	
	if($BRANCH eq 'release') {
	    $version = "$VERSION.$REVISION";
	} else {
	    $version = "$VERSION-$BRANCH-$REVISION";
	}

	$version =~ s{^(\d+\.)([\d.]*)}{
	    my $h = $1;
	    my $t = $2;
	    $t =~ s/(\d+)/sprintf "%3.3i", $1/ge;
	    $t =~ s/\.//g;
	    "$h$t";
	}e;
	return $self->{properties}{dist_version} = $version;
    }
    return $version;
}

sub fixup_version {
    my ($self, $file) = @_;
    local *FH;
    open FH, '<', $file or die "Can't read $file: $!";
    my $mod = 0;
    my @file = map {
	s{(\bVERSION\b.*)\btree-version\b}{
	    $mod = 1;
	    $1 . $self->{properties}{dist_version};}e;
	$_;
    } <FH>;
    close FH;
    return unless $mod;
    print "Fixing version in $file\n";
    open FH, '>', $file or die "Can't write $file: $!";
    print FH $_ foreach @file;
    close FH;
}

sub ACTION_distdir {
    my $self = shift;
    $self->depends_on('changelog');
    $self->depends_on('manifest');

    $self->SUPER::ACTION_distdir(@_);

    $self->fixup_version(File::Spec->catfile($self->dist_dir,
	    $self->{properties}{dist_version_from}))
	if $self->{properties}{dist_version_from};
}

sub process_pm_files {
    my $self = shift;

    $self->SUPER::process_pm_files(@_);

    $self->fixup_version(File::Spec->catfile($self->blib,
	    $self->{properties}{dist_version_from}))
	if $self->{properties}{dist_version_from};
}

1;

__END__

=head1 NAME

Module::Build::Arch - Module::Build extension for GNU Arch.

=head1 SYNOPSIS

  use Module::Build::Arch

=head1 DESCRIPTION

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Module::Build(3pm).

=cut
# arch-tag: 53951114-48ce-4efb-9ad1-a17d17fd2e3b
