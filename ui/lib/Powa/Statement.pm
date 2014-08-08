package Powa::Statement;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use Mojo::ByteStream 'b';
use Powa::Beautify;

sub listdb {
    my $self = shift;
    my $dbh  = $self->database();
    my $sql;

    $sql = $dbh->prepare(
        "SELECT DISTINCT dbname FROM powa_statements ORDER BY dbname");
    $sql->execute();
    my $databases = [];
    while ( my ( $dbname ) = $sql->fetchrow() ) {
        push @{$databases}, { dbname => $dbname };
    }
    $sql->finish();

    $self->stash( databases => $databases );

    $dbh->disconnect();
    $self->render();
}

sub showdb {
    my $self = shift;
    my $base_timestamp = undef;

    $base_timestamp = $self->config->{base_timestamp} if ( defined $self->config->{base_timestamp} );

    $self->render( 'base_timestamp' => $base_timestamp );
}

sub showdbquery {
    my $self = shift;
    my $dbh  = $self->database();
    my $dbname = $self->param('dbname');
    my $md5query = $self->param('md5query');
    my $base_timestamp = undef;

    my $sql = $dbh->prepare(
        "SELECT query FROM powa_statements WHERE dbname = ? AND md5query = ?"
    );
    $sql->execute($dbname,$md5query);

    my $query_raw = $sql->fetchrow();

    my $query = highlight_code( $query_raw );

    $base_timestamp = $self->config->{base_timestamp} if ( defined $self->config->{base_timestamp} );

    $self->stash( query => b($query), base_timestamp => $base_timestamp );

    $sql->finish();

    $dbh->disconnect();
    $self->render();
}

sub dbdata {
    my $self = shift;
    my $dbh  = $self->database();
    my $dbname      = $self->param("dbname");
    my $from        = $self->param("from");
    my $to          = $self->param("to");
    my $sql;

    $from = substr $from, 0, -3;
    $to = substr $to, 0, -3;
    $sql = $dbh->prepare(
        "SELECT total_calls, total_runtime,
            total_blks_read, total_blks_hit, query, md5query
        FROM powa_getstatdata_db(to_timestamp(?), to_timestamp(?), ?)
        ORDER BY total_calls DESC
        "
    );
    my $log = Mojo::Log->new;
    $sql->execute($from,$to,$dbname);

    my $stats = [];
    while ( my @row = $sql->fetchrow_array() ) {
        push @{$stats}, {
            row => \@row
        };
    }
    $sql->finish();

    $dbh->disconnect();
    $self->render( json => { data => $stats });
}


sub dbdata_agg {
    my $self = shift;
    my $dbh  = $self->database();
    my $id   = $self->param("id");
    my $from = $self->param("from");
    my $to   = $self->param("to");
    my $json = Mojo::JSON->new;
    my $sql;

    my $section = substr $id, 0, 4;
    my $dbname = substr $id, 5;

    $from = substr $from, 0, -3;
    $to = substr $to, 0, -3;

    my $tmp;
    my $groupby = "";
    my $blksize = "";
    if ( $section eq "call") {
        $tmp = "sum(total_runtime)/extract(epoch from total_mesure_interval) as runtime";
        $groupby = "GROUP BY ts,total_mesure_interval";
    } else {
        $blksize = ", (SELECT current_setting('block_size')::numeric AS blksize) setting";
        $tmp = "((shared_blks_read+local_blks_read+temp_blks_read)*blksize)/extract(epoch from total_mesure_interval) as total_blks_read,
            ((shared_blks_hit+local_blks_hit)*blksize)/extract(epoch from total_mesure_interval) as total_blks_hit";
    }

    $sql = $dbh->prepare(
        "SELECT (extract(epoch FROM ts)*1000)::bigint,
            $tmp
        FROM powa_getstatdata_sample_db(to_timestamp(?), to_timestamp(?), ?, 300)
        $blksize
        $groupby
        ORDER BY 1
        "
    );
    my $log = Mojo::Log->new;
    $sql->execute($from,$to,$dbname);

    my $data = [];
    my $series = {};
    if ( $section eq "call") {
        $series->{'total_calls'} = [];
        $series->{'runtime'} = [];
    } else {
        $series->{'total_blks_read'} = [];
        $series->{'total_blks_hit'} = [];
    }
    while ( my @tab = $sql->fetchrow_array() ) {
        if ( $section eq "call") {
            push @{$series->{'runtime'}},[ 0 + $tab[0], 0.0 + $tab[1] ];
        } else {
            push @{$series->{'total_blks_read'}},  [ 0 + $tab[0], 0.0 + $tab[1] ];
            push @{$series->{'total_blks_hit'}},   [ 0 + $tab[0], 0.0 + $tab[2] ];
        }
        }
    $sql->finish();

    if ( $section eq "call") {
        push @{$data}, { data => $series->{'runtime'}, label => 'query runtime per second' };
    } else {
        push @{$data}, { data => $series->{'total_blks_read'}, label => 'Total read (in Bps)' };
        push @{$data}, { data => $series->{'total_blks_hit'}, label => 'Total hit (in Bps)' };
    }

    $dbh->disconnect();
    my $properties = {};
    $properties->{legend}{show} = $json->false;
    $properties->{legend}{position} = "ne";
    $properties->{title} = "POWA - $section";
    if ( $section eq "call" ){
        $properties->{yaxis}{unit} = 'ms';
    } else {
        $properties->{yaxis}{unit} = 'Bps';
    }
    $properties->{yaxis}{autoscale} = $json->true;
    $properties->{yaxis}{autoscaleMargin} = 0.2;
    if ( $section eq "blks" ) {
        $properties->{lines}{stacked} = $json->true;
        $properties->{lines}{fill} = $json->true;
    }

    $self->render( json => {
        series      => $data,
        properties  => $properties
    } );
}

sub querydata {
    my $self = shift;
    my $dbh  = $self->database();
    my $id   = $self->param("id");
    my $from = $self->param("from");
    my $to   = $self->param("to");
    my $json = Mojo::JSON->new;
    my $sql;

    my $section = substr $id, 0, 3;
    my $md5query = substr $id, 3;

    my $tmp = "";
    my $blksize = ", (SELECT current_setting('block_size')::numeric AS blksize) setting";
    $blksize = "" if ($section eq "GEN") or ($section eq "TIM");
    $tmp = "round((total_runtime/CASE total_calls WHEN 0 THEN 1 ELSE total_calls END)::numeric,2), rows" if ($section eq "GEN");
    $tmp = "(shared_blks_hit*blksize)/extract(epoch from total_mesure_interval), (shared_blks_read*blksize)/extract(epoch from total_mesure_interval), (shared_blks_dirtied*blksize)/extract(epoch from total_mesure_interval), (shared_blks_written*blksize)/extract(epoch from total_mesure_interval)" if ($section eq "SHA");
    $tmp = "(local_blks_hit*blksize)/extract(epoch from total_mesure_interval), (local_blks_read*blksize)/extract(epoch from total_mesure_interval), (local_blks_dirtied*blksize)/extract(epoch from total_mesure_interval), (shared_blks_written*blksize)/extract(epoch from total_mesure_interval)" if ($section eq "LOC");
    $tmp = "(temp_blks_read*blksize)/extract(epoch from total_mesure_interval), (temp_blks_written*blksize)/extract(epoch from total_mesure_interval)" if ($section eq "TMP");
    $tmp = "blk_read_time, blk_write_time" if ($section eq "TIM");


    $from = substr $from, 0, -3;
    $to = substr $to, 0, -3;
    $sql = $dbh->prepare(
        "SELECT (extract(epoch FROM ts)*1000)::bigint,
        $tmp
        FROM powa_getstatdata_sample(to_timestamp(?), to_timestamp(?), ?, 300)
        $blksize
        ORDER BY ts
        "
    );
    #$sql->execute($md5query,$from,$to);
    $sql->execute($from,$to,$md5query);

    my $data = [];
    my $series = {};
    if ( $section eq "GEN" ){
        $series->{'avg_time'} = [];
        $series->{'rows'} = [];
    }
    if ( $section eq "SHA" ){
        $series->{'shared_blks_hit'} = [];
        $series->{'shared_blks_read'} = [];
        $series->{'shared_blks_dirtied'} = [];
        $series->{'shared_blks_written'} = [];
    }
    if ( $section eq "LOC" ){
        $series->{'local_blks_hit'} = [];
        $series->{'local_blks_read'} = [];
        $series->{'local_blks_dirtied'} = [];
        $series->{'local_blks_written'} = [];
    }
    if ( $section eq "TMP" ){
        $series->{'temp_blks_read'} = [];
        $series->{'temp_blks_written'} = [];
    }
    if ( $section eq "TIM" ){
        $series->{'blk_read_time'} = [];
        $series->{'blk_write_time'} = [];
    }
    while ( my @tab = $sql->fetchrow_array() ) {
        if ( $section eq "GEN" ){
            push @{$series->{'avg_time'}},            [ 0 + $tab[0], 0.0 + $tab[1] ];
            push @{$series->{'rows'}},                  [ 0 + $tab[0], 0.0 + $tab[2] ];
        }
        if ( $section eq "SHA" ){
            push @{$series->{'shared_blks_hit'}},       [ 0 + $tab[0], 0.0 + $tab[1] ];
            push @{$series->{'shared_blks_read'}},       [ 0 + $tab[0], 0.0 + $tab[2] ];
            push @{$series->{'shared_blks_dirtied'}},   [ 0 + $tab[0], 0.0 + $tab[3] ];
            push @{$series->{'shared_blks_written'}},   [ 0 + $tab[0], 0.0 + $tab[4] ];
        }
        if ( $section eq "LOC" ){
            push @{$series->{'local_blks_hit'}},        [ 0 + $tab[0], 0.0 + $tab[1] ];
            push @{$series->{'local_blks_read'}},        [ 0 + $tab[0], 0.0 + $tab[2] ];
            push @{$series->{'local_blks_dirtied'}},    [ 0 + $tab[0], 0.0 + $tab[3] ];
            push @{$series->{'local_blks_written'}},    [ 0 + $tab[0], 0.0 + $tab[4] ];
        }
        if ( $section eq "TMP" ){
            push @{$series->{'temp_blks_read'}},        [ 0 + $tab[0], 0.0 + $tab[1] ];
            push @{$series->{'temp_blks_written'}},     [ 0 + $tab[0], 0.0 + $tab[2] ];
        }
        if ( $section eq "TIM" ){
            push @{$series->{'blk_read_time'}},         [ 0 + $tab[0], 0.0 + $tab[1] ];
            push @{$series->{'blk_write_time'}},        [ 0 + $tab[0], 0.0 + $tab[2] ];
        }
    };
    $sql->finish();

        if ( $section eq "GEN" ){
            push @{$data}, { data => $series->{'avg_time'}, label => 'avg_time' };
            push @{$data}, { data => $series->{'rows'}, label => 'rows' };
        }
        if ( $section eq "SHA" ){
            push @{$data}, { data => $series->{'shared_blks_hit'}, label => 'Shared hit (in Bps)' };
            push @{$data}, { data => $series->{'shared_blks_read'}, label => 'Shared read (in Bps)' };
            push @{$data}, { data => $series->{'shared_blks_dirtied'}, label => 'Shared dirtied (in Bps)' };
            push @{$data}, { data => $series->{'shared_blks_written'}, label => 'Shared written (in Bps)' };
        }
        if ( $section eq "LOC" ){
            push @{$data}, { data => $series->{'local_blks_hit'}, label => 'Local hit (in Bps)' };
            push @{$data}, { data => $series->{'local_blks_read'}, label => 'Local read (in Bps)' };
            push @{$data}, { data => $series->{'local_blks_dirtied'}, label => 'Local dirtied (in Bps)' };
            push @{$data}, { data => $series->{'local_blks_written'}, label => 'Local written (in Bps)' };
        }
        if ( $section eq "TMP" ){
            push @{$data}, { data => $series->{'temp_blks_read'}, label => 'Temp read (in Bps)' };
            push @{$data}, { data => $series->{'temp_blks_written'}, label => 'Temp written (in Bps)' };
        }
        if ( $section eq "TIM" ){
            push @{$data}, { data => $series->{'blk_read_time'}, label => 'Read time' };
            push @{$data}, { data => $series->{'blk_write_time'}, label => 'Write time' };
        }

    $dbh->disconnect();
    my $properties = {};
    $properties->{legend}{show} = $json->false;
    $properties->{legend}{position} = "ne";
    $properties->{title} = "POWA $section";
    if ($section eq "GEN"){
        $properties->{yaxis}{unit} = '';
    } elsif ($section eq "TIM"){
        $properties->{yaxis}{unit} = 'ms';
    } else {
        $properties->{yaxis}{unit} = 'Bps';
    }
    $properties->{yaxis}{autoscale} = $json->true;
    $properties->{yaxis}{autoscaleMargin} = 0.2;
    $self->render( json => {
        series      => $data,
        properties  => $properties
    } );
}

# This function comes from pgBadger
# by Gilles Darold <gilles AT darold DOT net>
# licensed under PostgreSQL licence.
sub escape_html
{
    $_[0] =~ s/<([\/a-zA-Z][\s\t\>]*)/\&lt;$1/sg;

    return $_[0];
}

# This function comes from pgBadger
# by Gilles Darold <gilles AT darold DOT net>
# licensed under PostgreSQL licence.
sub highlight_code {
    my $code = shift;

    # Keywords variable
    my @pg_keywords = qw(
        ALL ANALYSE ANALYZE AND ANY ARRAY AS ASC ASYMMETRIC AUTHORIZATION BINARY BOTH CASE
        CAST CHECK COLLATE COLLATION COLUMN CONCURRENTLY CONSTRAINT CREATE CROSS
        CURRENT_DATE CURRENT_ROLE CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER
        DEFAULT DEFERRABLE DESC DISTINCT DO ELSE END EXCEPT FALSE FETCH FOR FOREIGN FREEZE FROM
        FULL GRANT GROUP HAVING ILIKE IN INITIALLY INNER INTERSECT INTO IS ISNULL JOIN LEADING
        LEFT LIKE LIMIT LOCALTIME LOCALTIMESTAMP NATURAL NOT NOTNULL NULL ON ONLY OPEN OR
        ORDER OUTER OVER OVERLAPS PLACING PRIMARY REFERENCES RETURNING RIGHT SELECT SESSION_USER
        SIMILAR SOME SYMMETRIC TABLE THEN TO TRAILING TRUE UNION UNIQUE USER USING VARIADIC
        VERBOSE WHEN WHERE WINDOW WITH
    );

    my @beautify_pg_keywords = qw(
        ANALYSE ANALYZE CONCURRENTLY FREEZE ILIKE ISNULL LIKE NOTNULL PLACING RETURNING VARIADIC
    );


    # Highlight variables
    my @KEYWORDS1 = qw(
        ALTER ADD AUTO_INCREMENT BETWEEN BY BOOLEAN BEGIN CHANGE COLUMNS COMMIT COALESCE CLUSTER
        COPY DATABASES DATABASE DATA DELAYED DESCRIBE DELETE DROP ENCLOSED ESCAPED EXISTS EXPLAIN
        FIELDS FIELD FLUSH FUNCTION GREATEST IGNORE INDEX INFILE INSERT IDENTIFIED IF INHERIT
        KEYS KILL KEY LINES LOAD LOCAL LOCK LOW_PRIORITY LANGUAGE LEAST LOGIN MODIFY
        NULLIF NOSUPERUSER NOCREATEDB NOCREATEROLE OPTIMIZE OPTION OPTIONALLY OUTFILE OWNER PROCEDURE
        PROCEDURAL READ REGEXP RENAME RETURN REVOKE RLIKE ROLE ROLLBACK SHOW SONAME STATUS
        STRAIGHT_JOIN SET SEQUENCE TABLES TEMINATED TRUNCATE TEMPORARY TRIGGER TRUSTED UN$filenumLOCK
        USE UPDATE UNSIGNED VALUES VARIABLES VIEW VACUUM WRITE ZEROFILL XOR
        ABORT ABSOLUTE ACCESS ACTION ADMIN AFTER AGGREGATE ALSO ALWAYS ASSERTION ASSIGNMENT AT ATTRIBUTE
        BACKWARD BEFORE BIGINT CACHE CALLED CASCADE CASCADED CATALOG CHAIN CHARACTER CHARACTERISTICS
        CHECKPOINT CLOSE COMMENT COMMENTS COMMITTED CONFIGURATION CONNECTION CONSTRAINTS CONTENT
        CONTINUE CONVERSION COST CSV CURRENT CURSOR CYCLE DAY DEALLOCATE DEC DECIMAL DECLARE DEFAULTS
        DEFERRED DEFINER DELIMITER DELIMITERS DICTIONARY DISABLE DISCARD DOCUMENT DOMAIN DOUBLE EACH
        ENABLE ENCODING ENCRYPTED ENUM ESCAPE EXCLUDE EXCLUDING EXCLUSIVE EXECUTE EXTENSION EXTERNAL
        FIRST FLOAT FOLLOWING FORCE FORWARD FUNCTIONS GLOBAL GRANTED HANDLER HEADER HOLD
        HOUR IDENTITY IMMEDIATE IMMUTABLE IMPLICIT INCLUDING INCREMENT INDEXES INHERITS INLINE INOUT INPUT
        INSENSITIVE INSTEAD INT INTEGER INVOKER ISOLATION LABEL LARGE LAST LC_COLLATE LC_CTYPE
        LEAKPROOF LEVEL LISTEN LOCATION LOOP MAPPING MATCH MAXVALUE MINUTE MINVALUE MODE MONTH MOVE NAMES
        NATIONAL NCHAR NEXT NO NONE NOTHING NOTIFY NOWAIT NULLS OBJECT OF OFF OIDS OPERATOR OPTIONS
        OUT OWNED PARSER PARTIAL PARTITION PASSING PASSWORD PLANS PRECEDING PRECISION PREPARE
        PREPARED PRESERVE PRIOR PRIVILEGES QUOTE RANGE REAL REASSIGN RECHECK RECURSIVE REF REINDEX RELATIVE
        RELEASE REPEATABLE REPLICA RESET RESTART RESTRICT RETURNS ROW ROWS RULE SAVEPOINT SCHEMA SCROLL SEARCH
        SECOND SECURITY SEQUENCES SERIALIZABLE SERVER SESSION SETOF SHARE SIMPLE SMALLINT SNAPSHOT STABLE
        STANDALONE START STATEMENT STATISTICS STORAGE STRICT SYSID SYSTEM TABLESPACE TEMP
        TEMPLATE TRANSACTION TREAT TYPE TYPES UNBOUNDED UNCOMMITTED UNENCRYPTED
        UNKNOWN UNLISTEN UNLOGGED UNTIL VALID VALIDATE VALIDATOR VALUE VARYING VOLATILE
        WHITESPACE WITHOUT WORK WRAPPER XMLATTRIBUTES XMLCONCAT XMLELEMENT XMLEXISTS XMLFOREST XMLPARSE
        XMLPI XMLROOT XMLSERIALIZE YEAR YES ZONE
    );

    foreach my $k (@pg_keywords) {
            push(@KEYWORDS1, $k) if (!grep(/^$k$/i, @KEYWORDS1));
    }

    my @KEYWORDS2 = (
        'ascii',      'age',
        'bit_length', 'btrim',
        'char_length', 'character_length', 'convert', 'chr', 'current_date', 'current_time', 'current_timestamp', 'count',
        'decode',      'date_part',        'date_trunc',
        'encode',      'extract',
        'get_byte',    'get_bit',
        'initcap',       'isfinite', 'interval',
        'justify_hours', 'justify_days',
        'lower', 'length', 'lpad', 'ltrim', 'localtime', 'localtimestamp',
        'md5',
        'now',
        'octet_length', 'overlay',
        'position',     'pg_client_encoding',
        'quote_ident',  'quote_literal',
        'repeat', 'replace', 'rpad', 'rtrim',
        'substring', 'split_part', 'strpos', 'substr', 'set_byte', 'set_bit',
        'trim', 'to_ascii', 'to_hex', 'translate', 'to_char', 'to_date', 'to_timestamp', 'to_number', 'timeofday',
        'upper',
    );
    my @KEYWORDS3 = ('STDIN', 'STDOUT');
    my %SYMBOLS = (
        '='  => '=', '<'  => '&lt;', '>' => '&gt;', '\|' => '|', ',' => ',', '\.' => '.', '\+' => '+', '\-' => '-', '\*' => '*',
        '\/' => '/', '!=' => '!='
    );
    my @BRACKETS = ('(', ')');
    map {$_ = quotemeta($_)} @BRACKETS;

    # Escape HTML code into SQL values
    $code = &escape_html($code);

    # Do not try to prettify queries longer
    # than 10KB as this will take too much time
    return $code if (length($code) > 10240);

    # prettify SQL query
    my $sql_prettified = Powa::Beautify->new(keywords => \@beautify_pg_keywords);
    $sql_prettified->query($code);
    $code = $sql_prettified->beautify;


    my $i = 0;
    my @qqcode = ();
    while ($code =~ s/("[^\"]*")/QQCODEY${i}A/s) {
        push(@qqcode, $1);
        $i++;
    }
    $i = 0;
    my @qcode = ();
    while ($code =~ s/('[^\']*')/QCODEY${i}B/s) {
        push(@qcode, $1);
        $i++;
    }

    foreach my $x (keys %SYMBOLS) {
        $code =~ s/$x/\$\$STYLESY0A\$\$$SYMBOLS{$x}\$\$STYLESY0B\$\$/gs;
    }
    for (my $x = 0 ; $x <= $#KEYWORDS1 ; $x++) {
        #$code =~ s/\b$KEYWORDS1[$x]\b/<span class="kw1">$KEYWORDS1[$x]<\/span>/igs;
        $code =~ s/(?<!(?-i)STYLESY0B\$\$)\b$KEYWORDS1[$x]\b/<span class="kw1">$KEYWORDS1[$x]<\/span>/igs;
    }

    for (my $x = 0 ; $x <= $#KEYWORDS2 ; $x++) {
        $code =~ s/(?<!:)\b$KEYWORDS2[$x]\b/<span class="kw2">$KEYWORDS2[$x]<\/span>/igs;
    }
    for (my $x = 0 ; $x <= $#KEYWORDS3 ; $x++) {
        $code =~ s/\b$KEYWORDS3[$x]\b/<span class="kw3">$KEYWORDS3[$x]<\/span>/igs;
    }
    for (my $x = 0 ; $x <= $#BRACKETS ; $x++) {
        $code =~ s/($BRACKETS[$x])/<span class="br0">$1<\/span>/igs;
    }

    $code =~ s/\$\$STYLESY0A\$\$([^\$]+)\$\$STYLESY0B\$\$/<span class="sy0">$1<\/span>/gs;

    $code =~ s/\b(\d+)\b/<span class="nu0">$1<\/span>/igs;

    for (my $x = 0; $x <= $#qcode; $x++) {
        $code =~ s/QCODEY${x}B/$qcode[$x]/s;
    }
    for (my $x = 0; $x <= $#qqcode; $x++) {
        $code =~ s/QQCODEY${x}A/$qqcode[$x]/s;
    }

    $code =~ s/('[^']*')/<span class="st0">$1<\/span>/gs;
    $code =~ s/(`[^`]*`)/<span class="st0">$1<\/span>/gs;

    return $code;
}

1;
