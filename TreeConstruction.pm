=pod
2022_12_07バージョン
生成規則A_D内で、イプシロン遷移が正常に受理されずdie;するバグを仮修正。とりあえず想定通りの動作するようになった
2022_10_16バージョン
兄弟関係を表す + を , に変更。生成規則名は+のままなので注意
2021_10_04バージョン
オブジェクトTreeObject形式でツリーとプレースを同時に返せるように。
オブジェクト内の機能についてはまだ検討中
2021_09_23バーション
属性名の指定と、属性の複数定義が可能になった。#{属性名}属性。{属性名}を{}ごと省略した場合、valに属性が入る。{}のみ記述するとエラー
接続口の指定、および根ノードに属性や接続口の指定が出来ない。未実装のまま放置中
2021_09_20バーション
val内容を指定可能に。また接続口の指定が可能に
どちらも未完成なため次バージョンで修正予定
2021_09_13バージョン
基本文字列以外の記号はバックスラッシュでエスケープ可能に変更。ただしバックスラッシュそのものはエスケープ不可
(予定)完成した木をハッシュの形式で返すように変更したい
=cut

# パッケージ名
package TreeConstruction;  
 
use Exporter;
#use OLTPN;
use TreeObject;
@ISA = (Exporter);
@EXPORT = qw(TreeConstruction);

use strict;
use warnings;
use utf8;

my $place = {};#プレース記憶用のハッシュ。プレース名がキー。
my $edge = {};#$placeの対応するキーのプレースに向かうエッジを記憶するハッシュ。

#字句解析(emmet風)
#2021/09/06　;無しで行終わりを判別可能に
sub OLTPNlexicalAnarysis{
    my ($code) = @_;#code
    my @tokens;

    #Bar();
    #print ("code length = ".length($code)."\n");

    my $i = 0;
    my $sentence = 0;#連続した文字を判定するふらぐ
    my $escape = 0;
    my $sharp = 0;#シャープ記号の連続を確認するフラグ
    while($i < length($code)){
	    my ($word) = substr($code,$i,1);
        #バックスラッシュで次のワードをエスケープ可能
        #意図的にバックスラッシュ自体をエスケープ不可能にしている

        #if (($word =~ /^[a-zA-Z0-9_:;={}\\]+$/)||($escape)){
        if($word eq "\\"){
            $escape = 1;
        }elsif (($word =~ /^[a-zA-Z0-9_\w]+$/)||($escape)){
            #print($word);
            $escape = 0;
            if($sentence){
                $tokens[$#tokens].=$word;
            }else{
                push(@tokens,$word);
                $sentence = 1;
            }
        }else{
            $sentence = 0;
            if ($word eq ">"){
                push(@tokens,"\\>");
            }elsif ($word eq "("){
                push(@tokens,"\\(");
            }elsif ($word eq ")"){
                push(@tokens,"\\)");
            }elsif ($word eq ","){
                push(@tokens,"\\,");
            }elsif ($word eq "-"){
                push(@tokens,"\\-");
            }elsif ($word eq "{"){
                push(@tokens,"\\{");
            }elsif ($word eq "}"){
                push(@tokens,"\\}");
            }elsif ($word eq "#"){
                #連続する##を#と区別
                if ($tokens[$#tokens] eq "\\#"){
                    $tokens[$#tokens].="#";
                }else{
                    push(@tokens,"\\#");
                }
            }else{
                #なにもしない
            }
        }
    	$i++;
    }
    push(@tokens,"\\;");

    #print("@tokens");

    return @tokens;
}

#えめっと風構文解析
#引数:字句解析後のトークン配列
sub OLTPNsyntaxAnalysis(@){
    my ($ref) = @_;
    my (@tokens) = @{$ref};

    sub Z($);
    sub A($);
    sub A2($);
    sub A3($);
    sub V($);
    sub V2($);
    sub A_D($);
    sub B($);
    sub B_D($);

    #print("\n");
    my $result = Z(\@tokens);
    #print("\n");

    sub Z($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nZ()--->");
        #print(@{$tokens});

        #先頭がエスケープでない場合にノード名
        if (substr($token,0,1) ne "\\"){

            shift(@{$tokens});
            my $token2 = @{$tokens}[0];
            if($token2 eq "\\>"){
                shift(@{$tokens});
                my $ret1 = A($tokens);
                my @children = ($ret1);
                return {'TYPE' => "Z", 'val' => $token, 'elem' => \@children};
            }elsif($token2 == undef){
                my @children = ();
                return {'TYPE' => "Z", 'val' => $token, 'elem' => \@children};
            }else{
                #名前 >以外でもエラー
                #print("error");
                die;
            }
        }else{
            #名前以外だとエラー
            #print("error");
            die;
        }
        return undef;
    }

    sub A($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nA()--->");
        #print(@{$tokens});
        #print(" --- ".$token);
        if($token eq "\\-"){
            shift(@{$tokens});
            my $ret1 = A2($tokens);
            my @children = ($ret1);
            return {'TYPE' => "A-", 'val' => 1, 'elem' => \@children};
        }else{
            #shift(@{$tokens});
            my $ret1 = A2($tokens);
            my @children = ($ret1);
            return {'TYPE' => "A", 'val' => 1, 'elem' => \@children};
        }
        
        return undef;#
    }

    sub A2($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nA2()--->");
        #print(@{$tokens});;
        #print(" --- ".$token);
        if (substr($token,0,1) ne "\\"){
            #shift(@{$tokens});
            my $ret1 = A3($tokens);
            my @children = ($ret1);
            return {'TYPE' => "A_nothing", 'val' => $token, 'elem' => \@children};
        }elsif($token eq "\\("){
            shift(@{$tokens});
            my $ret1 = A($tokens);
            $token = @{$tokens}[0];
            if($token eq "\\)"){
                shift(@{$tokens});
                my $ret2 = B_D($tokens);
                my @children = ($ret1);
                if ($ret2){
                    push(@children,$ret2);
                }
                return {'TYPE' => "A_(", 'val' => 1, 'elem' => \@children};
            }else{
                #print("error");
                die;
            }

        }elsif($token eq "\\##"){
            shift(@{$tokens});
            my $ret1 = A3($tokens);
            my @children = ($ret1);
            return {'TYPE' => "A_##", 'val' => $token, 'elem' => \@children};
            
        }else{
            #print("error");
            die;
        }
        return undef;#
    }

    sub A3($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nA3()--->");
        #print(@{$tokens});;
        #print(" --- ".$token);
        if (substr($token,0,1) ne "\\"){
            my $name = $token;
            shift(@{$tokens});
            $token = @{$tokens}[0];
            if($token eq "\\#"){
                shift(@{$tokens});
                my $ret1 = V($tokens);
                my @children = ($ret1);
                my $ret2 = A_D($tokens);
                if ($ret2){
                    push(@children,$ret2);
                }
                return {'TYPE' => "A3_name_#", 'val' => $name, 'elem' => \@children};
                
            }else{
                my $ret1 = A_D($tokens);
                my @children = ($ret1);
                return {'TYPE' => "A3_name", 'val' => $name, 'elem' => \@children};
            }

        }else{
                #print("error");
                die;
        }

        return undef;#
    }

    sub V($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nV()--->");
        #print(@{$tokens});;
        #print(" --- ".$token);
        if (substr($token,0,1) ne "\\"){
            shift(@{$tokens});
            my $ret1 = V2($tokens);
            my @children = ($ret1);
            return {'TYPE' => "V_val", 'val' => $token, 'elem' => \@children};
        }elsif($token eq "\\{"){
                shift(@{$tokens});
                $token = @{$tokens}[0];
                #{}内は属性名の記述が必須
                if (substr($token,0,1) ne "\\"){
                    my $val_name = $token;#属性名を保管
                    shift(@{$tokens});
                    $token = @{$tokens}[0];
                    if ($token eq "\\}"){
                        shift(@{$tokens});
                        $token = @{$tokens}[0];
                        if (substr($token,0,1) ne "\\"){
                            shift(@{$tokens});
                            my $ret1 = V2($tokens);
                            my @children = ($ret1);
                            return {'TYPE' => "V_val_name", 'val' => $token, 'elem' => \@children, 'val_name' => $val_name};
                        }else{
                            die;
                        }
                    }else{
                        die;
                    }
                }else{
                    die;
                }
        }else{
                #print("error");
                die;
        }
        return undef;#
    }

    sub V2($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nV2()--->");
        #print(@{$tokens});;
        #print(" --- ".$token);
        
        if ($token eq "\\#"){
            shift(@{$tokens});
            my $ret1 = V($tokens);
            my @children = ($ret1);
            return {'TYPE' => "V2_#", 'val' => 1, 'elem' => \@children};
        }else{
            #εの場合、elemは定義しない
            return {'TYPE' => "V2_ε", 'val' => 1};
        }

        return undef;#
    }

    sub A_D($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nA_D()--->");
        #print(@{$tokens});;
        #print(" --- ".$token);
        if($token eq "\\>"){
            shift(@{$tokens});
            my $ret1 = A($tokens);
            my @children = ($ret1);
            return {'TYPE' => "A_D_>", 'val' => 1, 'elem' => \@children};
        }elsif($token eq "\\,"){
            shift(@{$tokens});
            my $ret1 = A($tokens);
            my @children = ($ret1);
            return {'TYPE' => "A_D_+", 'val' => 1, 'elem' => \@children};
        }elsif($token eq "\\;"){
            #終了
            #print("A_D_end");
        }else{
            #εのとき
            #print("error");
            #die;
        }
        return undef;#なし
    }

    sub B_D($){
        my ($tokens) = @_;
        my $token = @{$tokens}[0];
        #print("\nB_D()--->");
        #print(@{$tokens});
        #print(" --- ".$token);
        if($token eq "\\,"){
            shift(@{$tokens});
            my $ret1 = A($tokens);
            my @children = ($ret1);
            return {'TYPE' => "B_D_+", 'val' => 1, 'elem' => \@children};
        }elsif($token eq "\\;"){
            #終了
            #print("B_D_end");
        }else{
            #εのとき
            #print("error");
            #die;
        }
        
        return undef;#
    }

    return $result;
}


#Emmet風構文木から木を生成
sub OLTPNcreateRec{
    my ($ref) = @_;
    my $type = exists $ref->{TYPE} ? $ref->{TYPE} : undef;#三項演算子
    my $val = $ref->{val};
    my @syntax_children = exists $ref->{elem} ? @{$ref->{elem}} : ();

    #Z,A_name,A_(,A_D_>,A_D_+,B_D_+
    if ($type eq '???'){
        #起こらない
        
    }else{
        
        if($type eq 'Z'){
            #print "---Z---\n";
            #ret1には配列のリファレンスが入るはずなのでそのままCHILDRENに追加
            my $ret1 = OLTPNcreateRec($syntax_children[0]);
            my $count = 0;#要素番号カウント
            foreach my $node (@{$ret1}){
                #print ("We are brother ".$node -> {type}."\n");
                if (exists($node -> {place})){
                    my $key_name = $node -> {type};
                    my @edge_data = ($ret1->[0], $count);#プレースの親ノードと、要素番号
                    $edge -> {$key_name} = \@edge_data;
                }
                $count++;
            }
            #my @children = ($ret1);
            return {'type' => $ref->{val}, 'val' => undef, 'elem' => $ret1};
        }elsif($type eq 'A'){
            #A2の中身(A_nameかA_(のどちらかなのでそのまま何もせず返す)
            #print "---A---\n";
            return OLTPNcreateRec($syntax_children[0]);
        }elsif($type eq 'A-'){
            #A_name、A_(のどちらの
            #print "---A-(minus)---\n";
            my $ret1 = OLTPNcreateRec($syntax_children[0]);
            #↓はこのままだと()内すべてにフラグをつけられない
            @{$ret1}[0]->{NOTOMIT} = 1;#頭に入っているのが直後のノードなのでタグを追加
            return $ret1;
        }elsif($type eq 'A3_name'){
            #これを簡単に書ける？A_nameの子供がA_D_>ならのような分岐を簡単に書ける？
            #if ($syntax_children[0]->{TYPE} eq 'A_D_>')を簡単に書ける関数を作ってみる？
            #A_name内をもっと短い行で書ける？
            #ライブラリ化するとどうなる→ライブラリの中は煩雑かもしれない
            #どこをどのように関数化するか考える必要がある

            #print "---A3_name---";

            if (exists ($syntax_children[0]->{TYPE})){
                my $ret1 = OLTPNcreateRec($syntax_children[0]);    
                if ($syntax_children[0]->{TYPE} eq 'A_D_>'){
                    #print "next_>---\n";
                    my @children = ({'type' => $ref->{val}, 'val' => undef, 'elem' => $ret1});
                    return \@children;
                }elsif($syntax_children[0]->{TYPE} eq 'A_D_+'){
                    #print "next_+---\n";
                    my @children = ({'type' => $ref->{val}, 'val' => undef, 'elem' => undef});
                    push(@children,@{$ret1});
                    return \@children;
                }else{
                    #起こらない？
                    #print "emptyerror---01\n";
                    die;
                }
            }else{
                #print "next_end---\n";
                my @children = ({'type' => $ref->{val}, 'val' => undef, 'elem' => undef});
                return \@children;
            }
                
        }elsif($type eq 'A3_name_#'){
            #print "---A3_name_#---\n";
            #print("val = ".$ref->{val});
            #%ret1はVおよびV2から得られるValueハッシュのリスト(のリファレンス)
            #なぜか奇数になっている(ハッシュは偶数であるはず)
            my %ret1 = OLTPNcreateRec($syntax_children[0]);
            my @children;#戻す木のリスト
            #$ret1->[0] -> {type} = $ref->{val};

            #A_Dの呼び出し部分
            if (exists ($syntax_children[1]->{TYPE})){
                my $ret2 = OLTPNcreateRec($syntax_children[1]);    
                if ($syntax_children[1]->{TYPE} eq 'A_D_>'){
                    #print "A3_#_next_>---\n";
                    @children = ({'type' => $ref->{val}, 'val' => undef, 'elem' => $ret2});
                }elsif($syntax_children[1]->{TYPE} eq 'A_D_+'){
                    #print "A3_#_next_+---\n";
                    @children = ({'type' => $ref->{val}, 'val' => undef, 'elem' => undef});
                    push(@children,@{$ret2});
                }else{
                    #print "emptyerror---01\n";
                    die;
                }
            }else{
                #print "next_end---\n";
                @children = ({'type' => $ref->{val}, 'val' => undef, 'elem' => undef});
            }

            #$children[0]に%ret1で取得したハッシュ(value)をマージ
            $children[0] = {%{$children[0]},%ret1};
            
            #$children[0] -> {val} = %ret1{'val'};
            #print("it is ... ".%ret1{'val'});

            return \@children;
            
        }elsif($type eq 'V_val'){
            #print "---V_val---";
            #print("val = ".$ref->{val});
            my %values = ('val' => $ref->{val});
            
            #戻り値とマージしたものを返す
            return (%values, OLTPNcreateRec($syntax_children[0]));
        }elsif($type eq 'V_val_name'){
            #print "---V_val_name---";
            #print("val = ".$ref->{val});
            #print(" val_name = ".$ref->{val_name});
            my %values = ($ref->{val_name} => $ref->{val});
            
            #戻り値とマージしたものを返す
            return (%values, OLTPNcreateRec($syntax_children[0]));
        }elsif($type eq 'V2_#'){
            #経由するのみ
            #print "---V2_#---\n";
            return OLTPNcreateRec($syntax_children[0]);
        }elsif($type eq 'V2_ε'){
            #εなので何も作らない
            #print "---V2_ε---\n";
            return undef;    
        }elsif($type eq 'A_nothing'){
            #print "---A_nothing---\n";
            return OLTPNcreateRec($syntax_children[0]);    
        }elsif($type eq 'A_##'){
            #print "---A_##---\n";
            my $ret1 = OLTPNcreateRec($syntax_children[0]);
            #ここでフラグ立てる
            $ret1 -> [0] -> {place} = 1;
            #プレース名をキーとして、placeハッシュにプレースのリファレンスを登録
            my $key_name = $ret1 -> [0] -> {type};
            $place -> {$key_name} = ($ret1 -> [0]);
            return $ret1;  
        }elsif($type eq 'A_('){
            #print "---A_(---\n";
            if (exists ($syntax_children[0]->{TYPE})){
                my $ret1 = OLTPNcreateRec($syntax_children[0]);
                if (exists ($syntax_children[1]->{TYPE})){
                    #B_Dの中身
                    my $ret2 = OLTPNcreateRec($syntax_children[1]); 
                    my @children = @{$ret1};
                    push(@children,@{$ret2});
                    return \@children;
                }else{
                    #B_Dが空
                    return $ret1;
                }
            }else{
                #カッコ内が空
                #print "error---\n";
                die;
            }

        }elsif($type eq 'A_D_>'){
            #A_nameまたはA_(から配列のリファレンスが返ってくるはずなのでそのまま返す
            #print "---A_D_>---\n";
            my $ret1 = OLTPNcreateRec($syntax_children[0]);
            foreach my $node (@{$ret1}){
                #print ("We are brother ".$node -> {type}."\n");
                if (exists($node -> {place})){
                   #print ("Whao it is place !!! ".$node -> {type}."\n");
                }
            }
            return $ret1;
            #my @children = ($ret1);
            #return {'TYPE' => $ref->{val}, 'val' => 1, 'elem' => \@children};
        }elsif($type eq 'A_D_+'){
            #Print "---A_D_+---\n";
            #A_nameまたはA_(から配列のリファレンスが返ってくるはずなのでそのまま返す
            return OLTPNcreateRec($syntax_children[0]);
        }elsif($type eq 'B_D_+'){
            return OLTPNcreateRec($syntax_children[0]);
        }elsif($type == undef){
            return undef;
        }else{
            #起こらない？
            #print "emptyerror---02\n";
            die;
        }
    }
    #起こらない？
    #print "emptyerror---03\n";
    die;
    return undef;
}

#OneLineTreePatternNotation　→ TreeConstruction(改名)
#引数：木の記述　戻り値：木のリファレンス
sub TreeConstruction{
    my ($code) = @_;#木の記述
    
    #print "this is ".$code. "\n";
    #字句解析
    my @tokens = OLTPNlexicalAnarysis($code);
    #構文解析
    my $tree = OLTPNsyntaxAnalysis(\@tokens);
    my @emptyArray = ();
    
    #OutputTree($tree,@emptyArray);
    
    #木を生成
    my $result = OLTPNcreateRec($tree);

    my $obj = TreeObject->new;
    $obj -> tree($result);
    $obj -> place($place);
    $obj -> edge($edge);

    return $obj;
}

1;