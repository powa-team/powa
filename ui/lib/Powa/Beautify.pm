package Powa::Beautify;

# Inclusion of Perl package SQL::Beautify
# Copyright (C) 2009 by Jonas Kramer
# Published under the terms of the Artistic License 2.0.


use strict;
use warnings;

use Carp;

    our $VERSION = 0.04;

    # Keywords from SQL-92, SQL-99 and SQL-2003.
    use constant KEYWORDS => qw(
        ABSOLUTE ACTION ADD AFTER ALL ALLOCATE ALTER AND ANY ARE ARRAY AS ASC
        ASENSITIVE ASSERTION ASYMMETRIC AT ATOMIC AUTHORIZATION AVG BEFORE BEGIN
        BETWEEN BIGINT BINARY BIT BIT_LENGTH BLOB BOOLEAN BOTH BREADTH BY CALL
        CALLED CASCADE CASCADED CASE CAST CATALOG CHAR CHARACTER CHARACTER_LENGTH
        CHAR_LENGTH CHECK CLOB CLOSE COALESCE COLLATE COLLATION COLUMN COMMIT
        CONDITION CONNECT CONNECTION CONSTRAINT CONSTRAINTS CONSTRUCTOR CONTAINS
        CONTINUE CONVERT CORRESPONDING COUNT CREATE CROSS CUBE CURRENT CURRENT_DATE
        CURRENT_DEFAULT_TRANSFORM_GROUP CURRENT_PATH CURRENT_ROLE CURRENT_TIME
        CURRENT_TIMESTAMP CURRENT_TRANSFORM_GROUP_FOR_TYPE CURRENT_USER CURSOR
        CYCLE DATA DATE DAY DEALLOCATE DEC DECIMAL DECLARE DEFAULT DEFERRABLE
        DEFERRED DELETE DEPTH DEREF DESC DESCRIBE DESCRIPTOR DETERMINISTIC
        DIAGNOSTICS DISCONNECT DISTINCT DO DOMAIN DOUBLE DROP DYNAMIC EACH ELEMENT
        ELSE ELSEIF END EPOCH EQUALS ESCAPE EXCEPT EXCEPTION EXEC EXECUTE EXISTS
        EXIT EXTERNAL EXTRACT FALSE FETCH FILTER FIRST FLOAT FOR FOREIGN FOUND FREE
        FROM FULL FUNCTION GENERAL GET GLOBAL GO GOTO GRANT GROUP GROUPING HANDLER
        HAVING HOLD HOUR IDENTITY IF IMMEDIATE IN INDICATOR INITIALLY INNER INOUT
        INPUT INSENSITIVE INSERT INT INTEGER INTERSECT INTERVAL INTO IS ISOLATION
        ITERATE JOIN KEY LANGUAGE LARGE LAST LATERAL LEADING LEAVE LEFT LEVEL LIKE
        LIMIT LOCAL LOCALTIME LOCALTIMESTAMP LOCATOR LOOP LOWER MAP MATCH MAX
        MEMBER MERGE METHOD MIN MINUTE MODIFIES MODULE MONTH MULTISET NAMES
        NATIONAL NATURAL NCHAR NCLOB NEW NEXT NO NONE NOT NULL NULLIF NUMERIC
        OBJECT OCTET_LENGTH OF OLD ON ONLY OPEN OPTION OR ORDER ORDINALITY OUT
        OUTER OUTPUT OVER OVERLAPS PAD PARAMETER PARTIAL PARTITION PATH POSITION
        PRECISION PREPARE PRESERVE PRIMARY PRIOR PRIVILEGES PROCEDURE PUBLIC RANGE
        READ READS REAL RECURSIVE REF REFERENCES REFERENCING RELATIVE RELEASE
        REPEAT RESIGNAL RESTRICT RESULT RETURN RETURNS REVOKE RIGHT ROLE ROLLBACK
        ROLLUP ROUTINE ROW ROWS SAVEPOINT SCHEMA SCOPE SCROLL SEARCH SECOND SECTION
        SELECT SENSITIVE SESSION SESSION_USER SET SETS SIGNAL SIMILAR SIZE SMALLINT
        SOME SPACE SPECIFIC SPECIFICTYPE SQL SQLCODE SQLERROR SQLEXCEPTION SQLSTATE
        SQLWARNING START STATE STATIC SUBMULTISET SUBSTRING SUM SYMMETRIC SYSTEM
        SYSTEM_USER TABLE TABLESAMPLE TEMPORARY TEXT THEN TIME TIMESTAMP
        TIMEZONE_HOUR TIMEZONE_MINUTE TINYINT TO TRAILING TRANSACTION TRANSLATE
        TRANSLATION TREAT TRIGGER TRIM TRUE UNDER UNDO UNION UNIQUE UNKNOWN UNNEST
        UNTIL UPDATE UPPER USAGE USER USING VALUE VALUES VARCHAR VARYING VIEW WHEN
        WHENEVER WHERE WHILE WINDOW WITH WITHIN WITHOUT WORK WRITE YEAR ZONE
    );


    sub tokenize_sql
    {
        my ($query, $remove_white_tokens) = @_;

        my $re = qr{
    (
        (?:--|\#)[\ \t\S]*      # single line comments
        |
        (?:<>|<=>|>=|<=|==|=|!=|!|<<|>>|<|>|\|\||\||&&|&|-|\+|\*(?!/)|/(?!\*)|\%|~|\^|\?)
                                # operators and tests
        |
        [\[\]\(\),;.]            # punctuation (parenthesis, comma)
        |
        \'\'(?!\')              # empty single quoted string
        |
        \"\"(?!\"")             # empty double quoted string
        |
        "(?>(?:(?>[^"\\]+)|""|\\.)*)+"
                                # anything inside double quotes, ungreedy
        |
        `(?>(?:(?>[^`\\]+)|``|\\.)*)+`
                                # anything inside backticks quotes, ungreedy
        |
        '(?>(?:(?>[^'\\]+)|''|\\.)*)+'
                                # anything inside single quotes, ungreedy.
        |
        /\*[\ \t\r\n\S]*?\*/      # C style comments
        |
        (?:[\w:@]+(?:\.(?:\w+|\*)?)*)
                                # words, standard named placeholders, db.table.*, db.*
        |
        (?: \$_\$ | \$\d+ | \${1,2})
                                # dollar expressions - eg $_$ $3 $$
        |
        \n                      # newline
        |
        [\t\ ]+                 # any kind of white spaces
    )
}smx;

        my @query = ();
        @query = $query =~ m{$re}smxg;

        if ($remove_white_tokens) {
            @query = grep(!/^[\s\n\r]*$/, @query);
        }

        return wantarray ? @query : \@query;
    }

    sub new
    {
        my ($class, %options) = @_;

        my $self = bless {%options}, $class;

        # Set some defaults.
        $self->{query}       = ''   unless defined($self->{query});
        $self->{spaces}      = 4    unless defined($self->{spaces});
        $self->{space}       = ' '  unless defined($self->{space});
        $self->{break}       = "\n" unless defined($self->{break});
        $self->{wrap}        = {}   unless defined($self->{wrap});
        $self->{keywords}    = []   unless defined($self->{keywords});
        $self->{rules}       = {}   unless defined($self->{rules});
        $self->{uc_keywords} = 0    unless defined $self->{uc_keywords};

        push(@{$self->{keywords}}, KEYWORDS);

        # Initialize internal stuff.
        $self->{_level} = 0;

        return $self;
    }

    # Add more SQL.
    sub add
    {
        my ($self, $addendum) = @_;

        $addendum =~ s/^\s*/ /;

        $self->{query} .= $addendum;
    }

    # Set SQL to beautify.
    sub query
    {
        my ($self, $query) = @_;

        $self->{query} = $query if (defined($query));

        return $self->{query};
    }

    # Beautify SQL.
    sub beautify
    {
        my ($self) = @_;

        $self->{_output}      = '';
        $self->{_level_stack} = [];
        $self->{_new_line}    = 1;

        my $last = '';
        $self->{_tokens} = [tokenize_sql($self->query, 1)];

        while (defined(my $token = $self->_token)) {
            my $rule = $self->_get_rule($token);

            # Allow custom rules to override defaults.
            if ($rule) {
                $self->_process_rule($rule, $token);
            }

            elsif ($token eq '(') {
                $self->_add_token($token);
                $self->_new_line;
                push @{$self->{_level_stack}}, $self->{_level};
                $self->_over unless $last and uc($last) eq 'WHERE';
            }

            elsif ($token eq ')') {
#               $self->_new_line;
                $self->{_level} = pop(@{$self->{_level_stack}}) || 0;
                $self->_add_token($token);
                $self->_new_line if ($self->_next_token
                            and $self->_next_token !~ /^AS$/i
                            and $self->_next_token ne ')'
                            and $self->_next_token !~ /::/
                            and $self->_next_token ne ';'
                    );
            }

            elsif ($token eq ',') {
                $self->_add_token($token);
                $self->_new_line;
            }

            elsif ($token eq ';') {
                $self->_add_token($token);
                $self->_new_line;

                # End of statement; remove all indentation.
                @{$self->{_level_stack}} = ();
                $self->{_level} = 0;
            }

            elsif ($token =~ /^(?:SELECT|FROM|WHERE|HAVING|BEGIN|SET)$/i) {
                $self->_back if ($last and $last ne '(' and $last ne 'FOR');
                $self->_new_line;
                $self->_add_token($token);
                $self->_new_line if ((($token ne 'SET') || $last) and $self->_next_token and $self->_next_token ne '(' and $self->_next_token ne ';');
                $self->_over;
            }

            elsif ($token =~ /^(?:GROUP|ORDER|LIMIT)$/i) {
                $self->_back;
                $self->_new_line;
                $self->_add_token($token);
            }

            elsif ($token =~ /^(?:BY)$/i) {
                $self->_add_token($token);
                $self->_new_line;
                $self->_over;
            }

            elsif ($token =~ /^(?:CASE)$/i) {
                $self->_add_token($token);
                $self->_over;
            }

            elsif ($token =~ /^(?:WHEN)$/i) {
                $self->_new_line;
                $self->_add_token($token);
            }

            elsif ($token =~ /^(?:ELSE)$/i) {
                $self->_new_line;
                $self->_add_token($token);
            }

            elsif ($token =~ /^(?:END)$/i) {
                $self->_back;
                $self->_new_line;
                $self->_add_token($token);
            }

            elsif ($token =~ /^(?:UNION|INTERSECT|EXCEPT)$/i) {
                $self->_back unless $last and $last eq '(';
                $self->_new_line;
                $self->_add_token($token);
                $self->_new_line if ($self->_next_token and $self->_next_token ne '(');
                $self->_over;
            }

            elsif ($token =~ /^(?:LEFT|RIGHT|INNER|OUTER|CROSS)$/i) {
                $self->_back;
                $self->_new_line;
                $self->_add_token($token);
                $self->_over;
            }

            elsif ($token =~ /^(?:JOIN)$/i) {
                if ($last and $last !~ /^(?:LEFT|RIGHT|INNER|OUTER|CROSS)$/) {
                    $self->_new_line;
                }

                $self->_add_token($token);
            }

            elsif ($token =~ /^(?:AND|OR)$/i) {
                $self->_new_line;
                $self->_add_token($token);
#               $self->_new_line;
            }

            elsif ($token =~ /^--/) {
                if (!$self->{no_comments}) {
                    $self->_add_token($token);
                    $self->_new_line;
                }
            }

            elsif ($token =~ /^\/\*.*\*\/$/s) {
                if (!$self->{no_comments}) {
                    $token =~ s/\n[\s\t]+\*/\n\*/gs;
                    $self->_new_line;
                    $self->_add_token($token);
                    $self->_new_line;
                }
            }

            else {
                $self->_add_token($token, $last);
            }

            $last = $token;
        }

        $self->_new_line;

        $self->{_output};
    }

    # Add a token to the beautified string.
    sub _add_token
    {
        my ($self, $token, $last_token) = @_;

        if ($self->{wrap}) {
            my $wrap;
            if ($self->_is_keyword($token)) {
                $wrap = $self->{wrap}->{keywords};
            } elsif ($self->_is_constant($token)) {
                $wrap = $self->{wrap}->{constants};
            }

            if ($wrap) {
                $token = $wrap->[0] . $token . $wrap->[1];
            }
        }

        my $last_is_dot = defined($last_token) && $last_token eq '.';

        if (!$self->_is_punctuation($token) and !$last_is_dot) {
            $self->{_output} .= $self->_indent;
        }

        # uppercase keywords
        $token = uc $token
            if $self->_is_keyword($token)
                and $self->{uc_keywords};

        $self->{_output} .= $token;

        # This can't be the beginning of a new line anymore.
        $self->{_new_line} = 0;
    }

    # Increase the indentation level.
    sub _over
    {
        my ($self) = @_;

        ++$self->{_level};
    }

    # Decrease the indentation level.
    sub _back
    {
        my ($self) = @_;

        --$self->{_level} if ($self->{_level} > 0);
    }

    # Return a string of spaces according to the current indentation level and the
    # spaces setting for indenting.
    sub _indent
    {
        my ($self) = @_;

        if ($self->{_new_line}) {
            return $self->{space} x ($self->{spaces} * $self->{_level});
        } else {
            return $self->{space};
        }
    }

    # Add a line break, but make sure there are no empty lines.
    sub _new_line
    {
        my ($self) = @_;

        $self->{_output} .= $self->{break} unless ($self->{_new_line});
        $self->{_new_line} = 1;
    }

    # Have a look at the token that's coming up next.
    sub _next_token
    {
        my ($self) = @_;

        return @{$self->{_tokens}} ? $self->{_tokens}->[0] : undef;
    }

    # Get the next token, removing it from the list of remaining tokens.
    sub _token
    {
        my ($self) = @_;

        return shift @{$self->{_tokens}};
    }

    # Check if a token is a known SQL keyword.
    sub _is_keyword
    {
        my ($self, $token) = @_;

        return ~~ grep {$_ eq uc($token)} @{$self->{keywords}};
    }

    # Add new keywords to highlight.
    sub add_keywords
    {
        my $self = shift;

        for my $keyword (@_) {
            push @{$self->{keywords}}, ref($keyword) ? @{$keyword} : $keyword;
        }
    }

    # Add new rules.
    sub add_rule
    {
        my ($self, $format, $token) = @_;

        my $rules = $self->{rules}    ||= {};
        my $group = $rules->{$format} ||= [];

        push @{$group}, ref($token) ? @{$token} : $token;
    }

    # Find custom rule for a token.
    sub _get_rule
    {
        my ($self, $token) = @_;

        values %{$self->{rules}};    # Reset iterator.

        while (my ($rule, $list) = each %{$self->{rules}}) {
            return $rule if (grep {uc($token) eq uc($_)} @$list);
        }

        return undef;
    }

    sub _process_rule
    {
        my ($self, $rule, $token) = @_;

        my $format = {
            break => sub {$self->_new_line},
            over  => sub {$self->_over},
            back  => sub {$self->_back},
            token => sub {$self->_add_token($token)},
            push  => sub {push @{$self->{_level_stack}}, $self->{_level}},
            pop   => sub {$self->{_level} = pop(@{$self->{_level_stack}}) || 0},
            reset => sub {$self->{_level} = 0; @{$self->{_level_stack}} = ();},
        };

        for (split /-/, lc $rule) {
            &{$format->{$_}} if ($format->{$_});
        }
    }

    # Check if a token is a constant.
    sub _is_constant
    {
        my ($self, $token) = @_;

        return ($token =~ /^\d+$/ or $token =~ /^(['"`]).*\1$/);
    }

    # Check if a token is punctuation.
    sub _is_punctuation
    {
        my ($self, $token) = @_;
        return ($token =~ /^[,;.]$/);
    }
