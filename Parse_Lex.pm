
use utf8; 
use strict;
use warnings;
package Parse_Lex;

require "Parser_y.pl";

our $IDENTIFIER; # 終端記号
our $NATURAL; # 終端記号

our $yylval;
our $yyval;

sub yyerror
{
    my ($msg) = @_;
    print "$msg\n";
    exit();
}

my $code;

sub bite_string
{
    my ($char,$rres)=@_;
    return bite_pattern('^' . quotemeta($char), $rres);
}

sub bite_pattern
{
    my ($pat, $rres) = @_;
    my $pre;

    $code =~ /^[\s\n\r]*/ or die "Error: Trap\n";
    $pre = $&;
    $code = $';

    if ($code =~ /$pat/)
    {
        $code = $';
        $$rres = { match => $&, pre => $pre };
        return 1;
    }
    else {return 0;}
}

sub set_yylval
{
    my ($type, $val) = @_;
    $yylval = {type =>$type, val => $val, elem => []};
}

sub yylex
{
    # This function read and truncate head of $code,
    # and set $yylval, and return token id.
    my $res;
    if (bite_string('|',\$res)){set_yylval('|', undef); return ord('|');}
    elsif (bite_string('>',\$res)){set_yylval('>', undef); return ord('>');}
    elsif (bite_string(',',\$res)){set_yylval(',', undef); return ord(',');}
    #一字しかreturnできないので変数を使うIDENTIFIERなど
    #elsif (bite_string('(?',\$res)){set_yylval('?', undef); return ord('?');}
    elsif (bite_string('(',\$res)){set_yylval('(', undef); return ord('(');}
    elsif (bite_string(')',\$res)){set_yylval(')', undef); return ord(')');}
    elsif (bite_string('{',\$res)){set_yylval('{', undef); return ord('{');}
    elsif (bite_string('}',\$res)){set_yylval('}', undef); return ord('}');}
    elsif (bite_string('*',\$res)){set_yylval('*', undef); return ord('*');}
    elsif (bite_string('##',\$res)){set_yylval('&', undef); return ord('&');}
    elsif (bite_string('#',\$res)){set_yylval('%', undef); return ord('%');}
    elsif (bite_string(':',\$res)){set_yylval(':', undef); return ord(':');}
    elsif (bite_string('.',\$res)){set_yylval('.', undef); return ord('.');}
    elsif (bite_string('?',\$res)){set_yylval('?', undef); return ord('?');}
    elsif (bite_string('-',\$res)){set_yylval('-', undef); return ord('-');}
    elsif (bite_string('$',\$res)){set_yylval('$', undef); return ord('$');}
    elsif (bite_string('!',\$res)){set_yylval('!', undef); return ord('!');}
    elsif (bite_pattern(qr/^[0-9]+/,\$res)){set_yylval('NATURAL', $res->{match}); return $NATURAL;}
    elsif (bite_pattern(qr/^[_A-Za-z][_A-Za-z0-9]*/,\$res)){set_yylval('IDENTIFIER', $res->{match}); return $IDENTIFIER;}
    elsif (bite_pattern(qr/^$/,\$res)){set_yylval('EOF', undef); return 0;}
    else{die "Error: yylex fail at '$code'!\n";}
}

sub parse
{
    $code = $_[0];

=pod
    #字句デバッグよう
    my $res;
    while($res = yylex){
        print($yylval -> {type}."\n");
    }
    exit 0;
=cut
    my $result = &yyparse();
    if($result != 0){ die "Parse failed!\n"; }

    return $yyval;
}

1;
