use Test;
use DBIish;
use DB::Migration::Simple;

my $verbose = False;

my $dbh = DBIish.connect("SQLite", :database<t/test-db.sqlite3>);

my $m = DB::Migration::Simple.new(:$dbh, :migration-file<t/migrations> :$verbose);
ok $m.dbh.^name eq 'DBDish::SQLite::Connection', "dbh installed in DB::Migration::Simple";
is-deeply $m.migration-file.IO.slurp.so, True, "migrations file exists";

ok $m.current-version == 0, 'current version is 0';

ok $m.migrate(:version<0>) eq '0', 'already at version 0';

# go to version 1
ok $m.migrate(:version<1>) eq '1', 'going to version 1';

# check table made, content inserted
try is-deeply select('SELECT * from table_version_1'), ([1, "This is version 1"],), 'table version 1 populated';
ok $!.^name eq Any.^name, "no error occured querying table_version_1";

# go to version 3
ok $m.migrate() eq '3', 'going to latest version (3)';
try is-deeply select('SELECT * from table_version_2'), (["This is version 2"],), 'table version 2 populated';
try is-deeply select('SELECT * from table_version_3'), (), 'table version 3 populated';

# go back to version 2
ok $m.migrate(:version<2>) eq '2', 'going back to version 2';
check-table-gone(3);

# go to version 0
ok $m.migrate(:version<0>) eq '0', 'going back to version 0';
check-table-gone(2);
check-table-gone(1);


sub select($stmt) {
    my $sth = $dbh.prepare($stmt);
    $sth.execute();
    return $sth.allrows();
}

sub check-table-gone($number) {
    try is-deeply select("SELECT * from table_version_$number"), (), "table version $number gone";
    ok $!, "error for querying non-existant 'table_version_$number' seen";
}
