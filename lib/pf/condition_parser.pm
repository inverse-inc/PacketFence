package pf::condition_parser;

=head1 NAME

pf::condition_parser - parser for filter logic

=cut

=head1 DESCRIPTION

pf::condition_parser

Parses the following BNF

EXPR = OR || OR
EXPR = OR
OR   = CMP && CMP
OR   = CMP
CMP  = VAL OP ID
CMP  = VAL OP STRING
CMP  = FACT
OP   = '==' | '!=' | '=~' | '!~' | '>' | '>=' | '<' | '<='
VAL  = ID
VAL  = FUNC
FUNC = ID '(' PARAMS ')'
PARAMS = PARAM ',' PARAMS
PARAMS = PARAM
PARAM  = VAR
PARAM  = STRING
PARAM  = FUNC
PARAM  = ID
VAR    = '${' VAR_ID '}'
VAR_ID = /[a-zA-Z0-9_]+(?:[\.-][a-zA-Z0-9_]+)*/
FACT = ! FACT
FACT = '(' EXPR ')'
FACT = ID
FACT = FUNC
ID   = /[a-zA-Z0-9_]+(\.[a-zA-Z0-9_])*/
STRING = "'" /([^'\\]|\\'|\\\\)+/  "'"
STRING = '"' /([^"\\]|\\"|\\\\)+/  '"'

=cut

use strict;
use warnings;
use pf::constants::condition_parser qw($TRUE_CONDITION);

use base qw(Exporter);

BEGIN {
    our @EXPORT_OK = qw(parse_condition_string ast_to_object);
}


=head2 parse_condition_string

Parses a string to a structure for building filters and conditions

    my ($ast, $err) = parse_condition_string('(a || b) && (c || d)');

On success

$ast will be the following structure

    $ast = [
              'AND',
              [
                'OR',
                'a',
                [
                  'AND',
                  'b',
                  'd'
                ]
              ],
              [
                'OR',
                'c',
                'd'
              ]
            ];

$err is an hash with an error message and the offset in

$err = {
    offset => 35, #Offset where the error happened
    message => "The error message",
    condition  => "The original condition string"
    highlighted_error => "The highlghted error",
}

If an invalid string is passed then the array will be undef and $msg will have have the error message

=cut

sub parse_condition_string {
    local $_ = shift;
    if (!defined $_) {
        return (undef, { message => "conditiom cannot be undefined", condition => undef });
    }
    pos() = 0;
    #Reduce whitespace
    /\G\s*/gc;
    my $expr = eval {_parse_expr()};
    if ($@) {
        return (undef, $@);
    }

    #Reduce whitespace
    /\G\s*/gc;

    #Check if there are any thing left
    if (/\G./gc) {
        my $position = pos;
        return (undef,format_parse_error("Invalid character(s)",$_ , $position - 1));
    }
    return ($expr, '');
}

=head2 _parse_expr

 EXPR = OR || OR
 EXPR = OR

=cut

sub _parse_expr {
    my @expr;
    push @expr, _parse_or();
    while (_or_operator()) {
        push @expr, _parse_or();
    }

    #collapse into a single element if there is only one
    return $expr[0] if @expr == 1;
    return ['OR', @expr];
}

=head2 _or_operator

Consume the or operator

=cut

sub _or_operator { /\G\s*\|{1,2}/gc }

=head2 _parse_or

OR   = CMP && CMP
OR   = CMP

=cut

sub _parse_or {
    my @expr;
    push @expr, _parse_cmp();
    while (_and_operator()) {
        push @expr, _parse_cmp();
    }

    #collapse into a single element if there is only one
    return $expr[0] if @expr == 1;
    return ['AND', @expr];
}

=head2 _and_operator

Consume the and operator

=cut

sub _and_operator { /\G\s*\&{1,2}/gc }

=head2 _parse_cmp

CMP  = VAL OP ID
CMP  = VAL OP STRING
CMP  = FACT

=cut

sub _parse_cmp {
    my $old_pos = pos();
    my $id = _parse_id();
    if (defined $id) {
        my $a = $id;
        if (/\G\s*\(/gc) {
            $a = _parse_func($id);
        }

        if (/\G\s*(==|!=|=~|!~|\<\=|\<|\>\=|\>)/gc) {
            my $op = $1;
            my $b = _parse_id() // _parse_string();
            if (!defined $b) {
                die format_parse_error("Invalid format", $_, pos);
            }

            return [$op,$a,$b];
        }
    }
    pos() = $old_pos;
    return _parse_fact();
}


=head2 _parse_num

_parse_num

=cut

sub _parse_num {
    my $n;
    if (/\G\s*([0-9]+)/gc) {
        $n = $1 + 0;
    }
    return $n;
}


=head2 _parse_string

_parse_string

=cut

sub _parse_string {
    my ($self) = @_;
    my $s = undef;
    if (/\G\s*"((?:[^"\\]|\\"|\\\\)*?)"/gc) {
        $s = $1;
        $s =~ s/\\"/"/g;
        $s =~ s/\\\\/\\/g;
    } elsif (/\G\s*'((?:[^'\\]|\\'|\\\\)*?)'/gc) {
        $s = $1;
        $s =~ s/\\'/'/g;
        $s =~ s/\\\\/\\/g;
    }
    return $s;
}

=head2 _parse_func

_parse_func

=cut

sub _parse_func {
    my $f = shift;
    my @params;
    my $b;
    if (/\G\s*\)/gc) {
        return ['FUNC', $f, \@params];
    }

    push @params, _parse_param();
    while (/\G\s*,\s*/gc) {
        push @params, _parse_param();
    }

    if (!/\G\s*\)/gc) {
        die format_parse_error("Function $f is not closed ", $_, pos);
    }

    return ['FUNC', $f, \@params];
}

sub _parse_param {
    my $p;
    if (defined ( $p = _parse_id())) {
        if (/\G\s*\(/gc) {
            $p = _parse_func($p);
        }
    } elsif ( defined($p = _parse_var_id())) {
        $p = ['VAR', $p];
    } else {
        $p = _parse_string();
    }

    if (!defined $p) {
        format_parse_error("Invalid parameter", $_, pos);
    }

    return $p;
}

=head2 _parse_fact

FACT = ! FACT
FACT = '(' EXPR ')'
FACT = /a-zA-Z0-9_/+
FACT = FUNC

=cut

sub _parse_fact {
    my $pos = pos();

    #Check if it is a not expression !
    if (/\G\s*!/gc) {
        my $fact = _parse_fact();
        return ['NOT', $fact];
    }

    #Check if it is a sub expression ()
    if (/\G\s*\(/gc) {
        my $expr = _parse_expr();

        #Checking for )
        return $expr if /\G\s*\)/gc;
        #Reduce whitespace
        /\G\s*/gc;
        die format_parse_error("No closing ')' invalid character or end of line found", $_, pos);
    }

    #It is a simple id
    my $id = _parse_id();
    if (defined $id) {
        if (/\G\s*\(/gc) {
            return _parse_func($id);
        }

        return $id;
    }
    #Reduce whitespace
    /\G\s*/gc;
    die format_parse_error("Invalid character(s)", $_, pos() );
}

=head2 _parse_id

_parse_id

=cut

sub _parse_id {
    my $id;
    if (/\G\s*([a-zA-Z0-9_]+(?:[\.-][a-zA-Z0-9_]+)*)/gc) {
        $id = $1;
    }

    return $id;
}

=head2 _parse_var_id

_parse_var_id

=cut

sub _parse_var_id {
    my $id;
    if (/\G\s*\$\{([a-zA-Z0-9_]+(?:[\.-][a-zA-Z0-9_]+)*)\}/gc) {
        $id = $1;
    }

    return $id;
}

our $MARKER  = '^';
our $HIGH_LIGHT = '~';


=head2 format_parse_error

format the parse to make easier to

=cut

sub format_parse_error {
    my ($error_msg, $string, $postion) = @_;
    return {
        offset => $postion,
        message => $error_msg,
        condition => $string,
        highlighted_error => highlight_error($error_msg, $string, $postion)
    };
}

=head2 highlight_error

format the parse to make easier to

=cut

sub highlight_error {
    my ($error_msg, $string, $postion) = @_;
    my $msg = "parse error: $error_msg\n$string\n";
    my $string_length = length($string);
    if ($postion == 0 ) {
        return  $msg . "$MARKER " . $HIGH_LIGHT x ($string_length - 2) . "\n";
    }
    my $pre_hilight = $HIGH_LIGHT x ($postion - 1)  . " ";
    my $post_repeat =  $string_length - length($pre_hilight) - 2;
    $post_repeat = 0 if $post_repeat < 0;
    my $post_hilight = " " . $HIGH_LIGHT x $post_repeat;
    return "${msg}${pre_hilight}${MARKER}${post_hilight}\n";
}

our %OPS_WITH_VALUES = (
    'AND' => 'and',
    'OR' => 'or',
);

our %OBJ_OPS = (
    and => '&&',
    or  => '||',
);

our %OBJ_NOT_OPS = (
    not_and => '&&',
    not_or  => '||',
);

our %OP_BINARY = (
#    %OPS_WITH_VALUES
    "==" => 'equals',
    "!=" => 'not_equals',
    "=~" => 'regex',
    "!~" => 'not_regex',
    ">"  => 'greater',
    ">=" => 'greater_equals',
    "<"  => 'lower',
    "<=" => 'lower_equals',
);

our %OP_BINARY_INVERSE = (
    "==" => 'not_equals',
    "!=" => 'equals',
    "=~" => 'not_regex',
    "!~" => 'regex',
    ">"  => 'lower_equals',
    ">=" => 'lower',
    "<"  => 'greater_equals',
    "<=" => 'greater',
);


our %ROP_BINARY = map { $OP_BINARY{$_} => $_ } keys %OP_BINARY;

sub ast_to_object {
    my ($ast) = @_;
    return _ast_to_object(@_);
}

sub _ast_to_object {
    my ($ast) = @_;
    if (ref $ast) {
        my $op = $ast->[0];
        if (exists $OPS_WITH_VALUES{$op}) {
            return { op => $OPS_WITH_VALUES{$op}, values => [map { _ast_to_object($_) } @{$ast}[1..(@{$ast} - 1)] ] };
        }

        if (exists $OP_BINARY{$op}) {
            return { op => $OP_BINARY{$op}, field => $ast->[1], value => $ast->[2] };
        }

        if ($op eq 'FUNC') {
            my ($f, $args) = @{$ast}[1,2];
            if ($f eq $TRUE_CONDITION) {
                return { op => $f };
            }
            return { op => $f, field => $args->[0], value => $args->[1] };
        }

        if ($op eq 'NOT') {
            my $sub = $ast->[1];
            my $sub_op = $sub->[0];
            if (exists $OPS_WITH_VALUES{$sub_op}) {
                return { op => "not_$OPS_WITH_VALUES{$sub_op}", values => [map { _ast_to_object($_) } @{$sub}[1..(@{$sub} - 1)] ] };
            }

            if (exists $OP_BINARY_INVERSE{$sub_op}) {
                return { op => $OP_BINARY_INVERSE{$sub_op}, field => $sub->[1], value => $sub->[2] };
            }

            return { op => "not_and", values => [ _ast_to_object($sub) ]};
        }

        return undef;
    }
    return { op => "var" , field => $ast };
}

sub object_to_str {
    my ($obj) = @_;
    my $str = _object_to_str($obj);
    if ($str =~ s/^\(//) {
        $str =~ s/\)$//;
    }
    return $str;
}

sub _object_to_str {
    my ($obj) = @_;
    my $op = $obj->{op};
    if ($op eq $TRUE_CONDITION) {
        return 'true()';
    }
    if (exists $OBJ_OPS{$op}) {
        my $values = $obj->{values};
        if ( @$values == 1 ) {
            return object_to_str(@$values);
        }

        return join('', '(', join( " $OBJ_OPS{$op} ", map { _object_to_str($_) } @$values ), ')' );
    }

    if (exists $OBJ_NOT_OPS{$op}) {
        my $values = $obj->{values};
        return join('', '!(', join( " $OBJ_NOT_OPS{$op} ", map { _object_to_str($_) } @$values ), ')' );
    }

    if (exists $ROP_BINARY{$op}) {
        my $value = $obj->{value};
        $value =~ s/(["\\])/\\$1/g;
        return "$obj->{field} $ROP_BINARY{$op} \"$value\"";
    }

    my $value = $obj->{value};
    $value =~ s/(["\\])/\\$1/g;
    return "$op($obj->{field}, \"$value\")";
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2024 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
