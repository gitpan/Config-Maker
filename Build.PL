use lib 'util';
use Module::Build::Arch;

my $build = Module::Build::Arch->new(
    module_name => 'Config::Maker',
    license => 'perl',
    requires => {
	perl => '5.6.1',
	'Parse::RecDescent' => '1.80',
    },
    script_files => [qw/configit/], # install run-and-save? it would go in examples somewhere...
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$build->create_build_script();

# arch-tag: 613614ef-4dbf-49d7-8531-1f4ca2b359c4
