NAME
====

DB::Migration::Simple - Simple DB migrations. Go up and down in versions.

SYNOPSIS
========

    use v6;
    use DB::Migration::Simple;
    use DBIish;

    my $dbh = DBIish.connect('SQLite', :database<example-db.sqlite3>);
    my $m = DB::Migration::Simple.new(:$dbh :migration-file<etc/migrations>);
    # optional parameter: $verbose
    # optional parameter: $migration-table-name

    $m.current-version();

    $m.migrate(version => 42);
    $m.migrate(); # migrate to latest version

DESCRIPTION
===========

DB::Migration::Simple is a Perl 6 module to help with up- and downgrading
a database schema between versions.

Write an SQL-file that specifies actions for up and migrations.

DB::Migration::Simple does not depend on certain databases or versions thereof.
It takes a dabatabase handle and trusts that the SQL you write will work with that handle.

Everything after a # is a comment.
Empty lines are ignored.
Only one statement per line.

Lines starting with "-- x up" denote the next version. Versions are integers.

Example
-------

    -- 1 up # comment
    CREATE TABLE table_version_1(id INTEGER PRIMARY KEY AUTOINCREMENT, msg TEXT)
    INSERT INTO table_version_1 (msg) VALUES("This is version 1")

    # comment

    --1 down
    DROP TABLE table_version_1


    -- 2 up
    CREATE TABLE table_version_2 (msg TEXT)
    INSERT INTO table_version_2 VALUES ("This is version 2")

    -- 2 down
    DROP TABLE table_version_2


    -- 3 up
    CREATE TABLE table_version_3 (msg TEXT)

    -- 3 down
    DROP TABLE table_version_3


Migrating up from version 0 (empty database) to version 2 will do the following.
- Migrate to version 1, using the commands under "-- 1 up".
- Migrate to version 2, using the commands under "-- 2 up".

Migrating down from version 2 to version 1 will use the commands under "-- 2 down".

The migrations are wrapped in a transacation. In case of failure, the commands
executed are rolled back, and you are left at the version before you called `$m.migrate()`.

Verbose Mode
------------
For debugging or other reasons of interest, supply the :verbose flag

    my $m = DB::Migration::Simple.new(:$dbh, :verbose<True>);

Metadata
--------
The migration meta information is stored in your database, in a table named "db-migration-simple-meta".
You can choose a different table name:

    $migration-table.name = 'my-own-migration-meta-table-that-suits-me-better';
    $m = DB::Migration::Simple.new(:$dbh :$migration-file :$migration-table-name);

AUTHOR
======

Matthias Bloch matthias.bloch@puffin.ch

This module was inspired by the Perl 5 Mojo::(DB-name-here)::Migrations modules.

COPYRIGHT AND LICENSE
=====================

Copyright © Matthias Bloch matthias.bloch@puffin.ch

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.