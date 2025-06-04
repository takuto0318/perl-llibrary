# stmc1_2_parser_yacc_part_plyg.pl の改変

use utf8;
use strict;
use warnings;

my $ply_file = "Parser_y.ply";
my $fh;

# 本ファイルの文字コードには
# utf8 (utf-8 BOM なし UTF-8N)、改行コード LF (unix) を用いる
# 
# 本ファイルにより Parser_y.ply  を作る
# kmyacc Parser_y.ply により Parser_y.pl を作る
# Parser_y.pl は Parse_Lex.pm から require(include) される。
# 
# Parse_Lex.pm がパーサモジュール(含む字句解析器)となる。
# プログラムで use Parse_Lex; または requre "./Parse_Lex.pm" などとする。
# 
# 
# 主な変数の説明
#
# @a_LHS_rules_list
# (: ARRAY)
# # LHS 毎の生成規則集合 (RH_LHS_RULES) を登場する順番に格納した配列
# =(
#   (type RH_LHS_RULES)
#   ...
# )
# 
# %h_LHS_to_LHS_rules
# (: HASH)
# # $LHS (非終端記号) に対し LHS 毎の生成規則集合 (type RH_LHS_RULES) を
# # 対応付けるハッシュ
# =(
#   $LHS => (type RH_LHS_RULES)
#   ...
# )
# 
# (type RH_LHS_RULES : REF_HASH)
# # LHS 毎の生成規則集合 (RH_LHS_RULES)
# ={
#   'comments' => (: REF_ARRAY_OF_STRING)
#     # LHS の前に現れるコメント
#     # 各行毎に1要素となる (無いときは [])
#     # "^# abc\n$" の形で書かれ、 " abc" として保存され、 
#     # "/* abc */\n" と出力される。
#   'LHS' => (: STRING)
#     # LHS (非終端記号) の名前
#   'rules' => (type RA_RULE_OF_LHS : REF_ARRAY)
#   # 生成規則のリスト
#   =[
#     (type RH_EACH_RULE : REF_ARRAY)
#     # 一つの生成規則
#     ={
#       'LHS' => (: STRING)
#       # 生成規則の左辺の非終端記号の名前
#       'nth_RHS' => (: INT)
#       # 同じ左辺の非終端記号を持つ生成規則の内、何番目の生成規則か
#       # を表す数 (1から始まる数)
#       'terms' => (RA_TERMS : REF_ARRAY)
#       # 右辺の各項からなるリスト、各項は、文字か、
#       # 文字以外の終端か非終端の記号か、アクションかのいずれか
#       =[
#         (type RH_TERM : REF_HASH)
#         ={
#           'type' => ('CHAR' | 'IDENTIFIER' | 'ACTION' : STRING)
#           # この項が単一文字の時 'CHAR' を、
#           # 単一文字以外の終端か非終端の記号の時、IDENTIFIER を
#           # アクションのとき 'ACTION' をとる
#           'string' => (: STRING)
#           # 項の内容、例えばこの項が文字 'x' の時 "x" を(' を含めない)、
#           # 文字以外の終端か非終端の記号 ABC の時、"ABC" を
#           # アクション {abc;} のとき "abc;" をとる
#         }
#         ...
#       ]
#     }
#   ]
# }
# $pre_part (:STRING)
# 1番目の '^%%\n' の行より前の部分を表す
# $post_part (:STRING)
# 2番目の '^%%\n' の行より後の部分を表す

# Read and analyse DATA contents

##    $ra_LHS,$rh_rules; => 次に変更
my @a_LHS_rules_list;
my %h_LHS_to_LHS_rules;
my ($pre_part,$post_part);
# my ($comment_string); $comment_string=''; 次に変更

my $LHS;
my $rh_current_LHS_rules; # (type RH_LHS_RULES : REF_HASH)
my $part;
my $ra_next_comments;

################################################################
# Read DATA (YACC Rules in tail of this file)
################################################################

$LHS='';
undef $rh_current_LHS_rules;

$ra_next_comments=[];
$part=0;

my $line;
while($line=<DATA>)
{
    if($line=~/^\%\%/){$part++;next;}
    if($part == 0) { $pre_part .= $line; }
    elsif($part >= 2) { $post_part .= $line; }
    else
    {
        chomp $line;

        # 行頭にコメント記号が有る場合、次の LHS のコメントとして
        # 使うために保存する
        if($line=~/^\/\/(.*)/) { push(@$ra_next_comments,$1); next; }

        # コメントの除去をしてから継続行の処理をする
        $line=~s/\/\/.*//; 
        while(! $line=~/\\\s*$/)
        {
            $line=~s/\\\s*$/\ /;
            $line .= <DATA>;
            chomp $line; $line=~s/\/\/.*//;
        }

        $line=~s/\s*$//;

        if($line eq '') { next; } # 空行の場合
        elsif($line=~/^\s+\:(\d+)/)
        {
            # 右辺の場合

            &dieX("Error!(1)\n") if !defined $rh_current_LHS_rules;

            my $nth_RHS = $1;
            $line=$';

            &dieX("Error!(2)\n")
                unless 1+(scalar @{$rh_current_LHS_rules->{'rules'}}) == $nth_RHS;
            my $rule = {'LHS'=>$LHS,'nth_RHS'=>$nth_RHS,'terms'=>[]};

            while($line ne '')
            {
                my $term = &pick_1st_term(\$line);
                push(@{$rule->{'terms'}},$term);
            }
            push(@{$rh_current_LHS_rules->{'rules'}},$rule);
        }
        elsif($line=~/^\S/)
        {
            my $term = &pick_1st_term(\$line);
            &dieX("Error!(3)\n") if $term->{'type'} ne 'IDENTIFIER';

            $LHS=$term->{'string'};

            &dieX("Error!(4)\n") unless $line =~ /^\s*$/;
            if(!exists $h_LHS_to_LHS_rules{$LHS})
            {
                $rh_current_LHS_rules
                  = {
                      'comments' => $ra_next_comments,
                      'LHS' => $LHS, 
                      'rules' => []
                  };
                push(@a_LHS_rules_list,$rh_current_LHS_rules);
                $h_LHS_to_LHS_rules{$LHS}=$rh_current_LHS_rules;
            }
            $rh_current_LHS_rules=$h_LHS_to_LHS_rules{$LHS};

            push(@{$rh_current_LHS_rules->{'comments'}},@$ra_next_comments);
            $ra_next_comments=[];
        }
        else
        {
            &dieX("Error!(5)($line)\n");
        }
    }
}

# {use Dumpvalue; my $dumper = new Dumpvalue; $dumper->dumpValue(\@a_LHS_rules_list);}

################################################################
# Write to .ply file
################################################################

open ($fh,">:raw:utf8", $ply_file)
    || &dieX("Can't open output file\n");

print $fh "/*  this file is automatically generated  */\n";

print $fh $pre_part . "%%\n";

for $rh_current_LHS_rules(@a_LHS_rules_list)
{
    # output comment

    for my $comment(@{$rh_current_LHS_rules->{'comments'}})
    {
        print $fh "/* " . $comment . " */\n";
    }
    
    # output LHS : 

    print $fh 'l@' . $rh_current_LHS_rules->{'LHS'} . "\n";

    my @RHS_lines;
    @RHS_lines=();

    &dieX("Error(7)!\n") unless 0 < scalar @{$rh_current_LHS_rules->{'rules'}};

    for my $rule(@{$rh_current_LHS_rules->{'rules'}})
    {
        my @RHS_term_strings;
        my ($i,$num_letter);
        my $last_action;
        @RHS_term_strings=();
        $num_letter=0;
        $last_action='';
        for($i=$[; $i<=$#{$rule->{'terms'}};$i++)
        {
            my $term=$rule->{'terms'}->[$i];
            my $is_last_term = $i==$#{$rule->{'terms'}};

            if($term->{'type'} eq 'IDENTIFIER')
            {
                push(@RHS_term_strings,
                    "r$num_letter" . '@' . $term->{'string'});
                $num_letter++;
            }
            elsif($term->{'type'} eq 'CHAR')
            {
                push(@RHS_term_strings,
                    "r$num_letter" . '@' . "'" . $term->{'string'} . "'");
                $num_letter++;
            }
            elsif($term->{'type'} eq 'ACTION')
            {
                if($is_last_term)
                {
                    $last_action=$term->{'string'};
                    last;
                }
                push(@RHS_term_strings, '{' . $term->{'string'} . '}')
            }
            else { &dieX("Error(8)!\n"); }
        }

        push(@RHS_lines,
            join(" ",@RHS_term_strings) . "\n"
            . '      {'
            . &normal_action($rule->{'LHS'},$rule->{'nth_RHS'},$num_letter)
            . $last_action . '}' . "\n"
            );
    }

    print $fh "    : " . join ("    | ", @RHS_lines) . "    ;\n";
}

print $fh "%%\n" . $post_part;

print STDERR "File '$ply_file' is created!\n";

################################################################
# to .ply file
################################################################

print STDERR "==== Executing kmyacc...\n";
{
    my $ret = system "kmyacc $ply_file";
    if ($? == -1)
    {
        print "==== failed to execute 'kmyacc': $!\n";
    }
    elsif ($? & 127)
    {
        printf "==== 'kmyacc' died with signal %d, %s coredump\n",
           ($? & 127),  ($? & 128) ? 'with' : 'without';
    }
    elsif (($? >> 8)!=0)
    {
        printf "==== kmyacc exited with value %d\n", $? >> 8;
    }
    else {
        printf "==== kmyacc done.\n";
    }
}

################################################################
# Utility subroutines
################################################################

sub normal_action
{
    my($NT_name,$rule_num,$num_letter)=@_;
    my ($i,$result);
    $result="l={'type' => 'NT:$NT_name:$rule_num', 'elem'=>[";
    $result.=join ",", map {"r$_"} (0..$num_letter-1);
    $result.="]};";
    #for($i=0;$i<$num_letter;$i++)
    #{
        #$result.=" r$i->" . q!{'up'}=l;!; 
    #}
    $result;
}


sub pick_1st_term
{
    # 文字列から最初の term ('x', abc, {hogehoge;} のいずれかの形式) を
    # 取り出す。
    # 引数へは文字列へのリファレンスを与える
    # 戻り値は (type RH_TERM : REF_ARRAY)
    # 先頭の空白は取り除く。引数の指す文字列から term が取り除かれる。

    my $rs_line=$_[0];

    $$rs_line=~s/^\s*//;
    if($$rs_line=~/^[_A-Za-z][_A-Za-z0-9]*/)
    {
        $$rs_line=$';
        return {'type' => 'IDENTIFIER', 'string' => $&};
    }
    elsif($$rs_line=~/^\'([^\'])\'/)
    {
        $$rs_line=$';
        return {'type' => 'CHAR', 'string' => $1};
    }
    elsif($$rs_line=~/^\{/)
    {
        $$rs_line=$';
        my $cb_cnt=1;
        my @chars=('{');
        my $head_char;
        while($cb_cnt>0)
        {
            $$rs_line=~/^./ or &dieX("Error(9)\n");
            $$rs_line=$';
            $head_char=$&;

            if($head_char eq '{') {$cb_cnt++;}
            elsif($head_char eq '}') {$cb_cnt--;}
            else {}

            push (@chars,$head_char);
        }
        shift(@chars); pop(@chars);
        return {'type' => 'ACTION', 'string' => join('',@chars)};
        # {{}}
    }
    else
    {
        &dieX("Error!(10)($$rs_line)\n");
    }
}
sub dieX
{
    die "DATA line=$.; " . $_[0];
}

################################################################

__DATA__

%{
################################################################
# This file is automatically generated.
################################################################
%}

%token EOF

%token IDENTIFIER
%token NATURAL

%%
// 2nd part

start
    :1 select
select
        :1 select '|' family
        :2 family
family
        :1 _label '>' family
        :2 _label family
        :3 _label
_label
        :1 IDENTIFIER ':' pre_node_option
        :2 pre_node_option
        :3 '?' '-' NATURAL
pre_node_option
        :1 '-' pre_node_option_2
        :2 pre_node_option_2 '$'
        :3 '-' pre_node_option_2 '$'
        :4 pre_node_option_2
pre_node_option_2
        :1 '!' pre_node
        :2 pre_node '*'
        :3 '!' pre_node '*'
        :4 pre_node
pre_node
        :1 '(' start ')'
        :2 node
node
        :1 type_name
        :2 type_name val_rep
        :3 type_name val_rep place
        :4 type_name place
type_name
        :1 '.'
        :2 IDENTIFIER
val_rep
        :1 val val_rep
        :2 val
val
        :1 '%' '{' IDENTIFIER '}' IDENTIFIER
        :2 '%' IDENTIFIER 
place
        :1 '&' IDENTIFIER

%%
################################################################
# 3rd part of yacc file
################################################################


1;


