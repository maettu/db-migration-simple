use v6;

class DB::Migration::Simple {
    has $.verbose = False;
    has $.dbh is required;
    has $.migration-file is required;
    has $.migration-table-name = 'db-migrations-simple-meta';
    has %!cfg = self!read-config();

    method current-version() {
        try {
            my $sth = $!dbh.prepare(qq:to/END-STATEMENT/);
                SELECT value FROM '$!migration-table-name'
                    WHERE key = 'current-version'
            END-STATEMENT
            $sth.execute();
            my @rows = $sth.allrows();
            $sth.finish();
            self!debug("current-version: allrows: "~@rows.gist);
            return @rows[0][0];
        }
        if $! {
            self!init-meta-table();
        }
        return 0;
    }

    method migrate(:$version = 'latest') {
        my Int $current-version = self.current-version();

        self!debug(%!cfg);

        my $v = $version;
        $v = %!cfg.keys.sort.reverse[0] if $v eq 'latest';

        my Int $target-version = $v.Int;
        self!debug("migrating from version '$current-version' to version '$target-version'");
        if $current-version == $target-version {
            self!debug("DB already at version $version");
            return $version;
        }
        my $direction = ($current-version < $target-version) ?? 'up' !! 'down';

        self!debug("$!verbose migrating '$direction' from version '$current-version' to version '$target-version'");

        $!dbh.do('BEGIN TRANSACTION');
        # TODO unelegant
        my $up = 0;
        my $down = 0;
        $up = 1 if $direction eq 'up';
        $down = 1 if $direction eq 'down';
        for ($current-version+$up ... $target-version+$down) -> $version {
            self!debug("doing '$direction' migrations for $version");

            # TODO this seems unelegant
            next if %!cfg{$version}{$direction}.^name eq 'Any';

            for |%!cfg{$version}{$direction} -> $stmt {
                self!debug("executing $stmt");
                try $!dbh.do($stmt);
                if $! {
                    $!dbh.do('ROLLBACK');
                    self!debug("error: $!");
                    return False;
                }
            }
        }
        $!dbh.do(qq:to/END-STATEMENT/);
            UPDATE '$!migration-table-name'
                SET value = '$target-version'
                WHERE key = 'current-version'
        END-STATEMENT
        $!dbh.do('COMMIT');
        return $target-version;
    }

    method !read-config() {
        my %cfg;
        my $version;
        my $direction;
        for $!migration-file.IO.slurp().split(/\n/) -> $l {
            # get rid of comments and empty lines
            my $line = $l;
            next if $line ~~ /^\s*$/;
            next if $line ~~ /^\s*\#/;

            self!debug("line: $line");

            # everything after a line starting with "--" belongs together
            if $line ~~ /^'--' \s* (\d+) \s* (up|down)/ {
                $version = $0;
                $direction = $1;
                self!debug("version: $version, direction: $direction");
                next;
            }

            %cfg{$version}{$direction}.push($line);
        }
        return %cfg;
    }

    method !debug($msg) {
        note $msg if $!verbose;
    }

    method !init-meta-table() {
        self!debug("initializing $!migration-table-name");
        $!dbh.do(qq:to/END-STATEMENT/);
            CREATE TABLE IF NOT EXISTS '$!migration-table-name' (
                key     TEXT UNIQUE NOT NULL,
                value   INTEGER NOT NULL CHECK (value >= 0)
            )
        END-STATEMENT

        $!dbh.do(qq:to/END-STATEMENT/);
            INSERT INTO '$!migration-table-name'
                VALUES ('current-version', 0)
        END-STATEMENT
        self!debug("set initial version to 0");
    }
}
