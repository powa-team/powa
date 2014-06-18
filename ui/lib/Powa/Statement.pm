package Powa::Statement;

# This program is open source, licensed under the PostgreSQL Licence.
# For license terms, see the LICENSE file.

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Digest::SHA qw(sha256_hex);

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
    my $dbh  = $self->database();

    $self->render();
}

sub showdbquery {
    my $self = shift;
    my $dbh  = $self->database();
    my $dbname = $self->param('dbname');
    my $md5query = $self->param('md5query');

    my $sql = $dbh->prepare(
        "SELECT query FROM powa_statements WHERE dbname = ? AND md5query = ?"
    );
    $sql->execute($dbname,$md5query);

    my $query = $sql->fetchrow();
    $self->stash( query => $query );

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
        $tmp = "(shared_blks_read+local_blks_read+temp_blks_read)*blksize as total_blks_read,
            (shared_blks_hit+local_blks_hit)*blksize as total_blks_hit";
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
        push @{$data}, { data => $series->{'total_blks_read'}, label => 'total_blks_read (in B)' };
        push @{$data}, { data => $series->{'total_blks_hit'}, label => 'total_blks_hit (in B)' };
    }

    $dbh->disconnect();
    my $properties = {};
    $properties->{legend}{show} = $json->false;
    $properties->{legend}{position} = "ne";
    $properties->{title} = "POWA - $section";
    if ( $section eq "call" ){
        $properties->{yaxis}{unit} = 'ms';
    } else {
        $properties->{yaxis}{unit} = 'B';
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
    $tmp = "shared_blks_hit*blksize, shared_blks_read*blksize, shared_blks_dirtied*blksize, shared_blks_written*blksize" if ($section eq "SHA");
    $tmp = "local_blks_hit*blksize, local_blks_read*blksize, local_blks_dirtied*blksize, shared_blks_written*blksize" if ($section eq "LOC");
    $tmp = "temp_blks_read*blksize, temp_blks_written*blksize" if ($section eq "TMP");
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
            push @{$data}, { data => $series->{'shared_blks_hit'}, label => 'shared_blks_hit (in B)' };
            push @{$data}, { data => $series->{'shared_blks_read'}, label => 'shared_blks_read (in B)' };
            push @{$data}, { data => $series->{'shared_blks_dirtied'}, label => 'shared_blks_dirtied (in B)' };
            push @{$data}, { data => $series->{'shared_blks_written'}, label => 'shared_blks_written (in B)' };
        }
        if ( $section eq "LOC" ){
            push @{$data}, { data => $series->{'local_blks_hit'}, label => 'local_blks_hit (in B)' };
            push @{$data}, { data => $series->{'local_blks_read'}, label => 'local_blks_read (in B)' };
            push @{$data}, { data => $series->{'local_blks_dirtied'}, label => 'local_blks_dirtied (in B)' };
            push @{$data}, { data => $series->{'local_blks_written'}, label => 'local_blks_written (in B)' };
        }
        if ( $section eq "TMP" ){
            push @{$data}, { data => $series->{'temp_blks_read'}, label => 'temp_blks_read (in B)' };
            push @{$data}, { data => $series->{'temp_blks_written'}, label => 'temp_blks_written (in B)' };
        }
        if ( $section eq "TIM" ){
            push @{$data}, { data => $series->{'blk_read_time'}, label => 'blk_read_time' };
            push @{$data}, { data => $series->{'blk_write_time'}, label => 'blk_write_time' };
        }

    $dbh->disconnect();
    my $properties = {};
    $properties->{legend}{show} = $json->false;
    $properties->{legend}{position} = "ne";
    $properties->{title} = "POWA $section";
    if ($section eq "GEN"){
        $properties->{yaxis}{unit} = '';
    } elsif ($section eq "TIM"){
        $properties->{yaxis}{unit} = 's';
    } else {
        $properties->{yaxis}{unit} = 'B';
    }
    $properties->{yaxis}{autoscale} = $json->true;
    $properties->{yaxis}{autoscaleMargin} = 0.2;
    $self->render( json => {
        series      => $data,
        properties  => $properties
    } );
}

1;
