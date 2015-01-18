#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use feature 'say';
use utf8;
use open qw(:std :utf8);

use Carp;
use File::Slurp;

use lib::abs qw(
    ../lib
);
use Curry::DB;

# main
sub main {

    my $content = read_file(
        '/curry/data/sql_structure',
        {
            binmode => ':utf8',
        },
    );

    get_db()->execute( $content );

}
main();
__END__
