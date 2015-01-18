package Curry::DB;

use strict;
use warnings FATAL => 'all';
use utf8;
use open qw(:std :utf8);

use SQL::Easy;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    get_db
);
our @EXPORT = @EXPORT_OK;

my $dbh = DBI->connect("dbi:SQLite:dbname=/curry/data/db.sqlite","","");

my $se = SQL::Easy->new(
    dbh => $dbh,
);

sub get_db {
    return $se;
}

1;
