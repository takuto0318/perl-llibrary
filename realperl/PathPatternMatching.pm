package PathPatternMatching; 
#カレントディレクトリを追加しないとモジュールが見つからない
#use lib qw(./);

#use myPerl;
#use OLTPN;

use Exporter;
@ISA = (Exporter);
@EXPORT = qw(PathPatternMatching);

use PathMatchingObject;

use strict;
use warnings;
use utf8;

#グローバル変数
my @tokens;

sub PathPatternMatching{
    my($code,$tree) = @_;#code

    @tokens = PathLexicalAnarysis($code);
    my $syntax_tree = PathSyntaxAnalysis();
    my $abstract_syntax_tree = MakeAbstractPathSyntaxTree_2($syntax_tree);
    my $NFA = CreateNFA($abstract_syntax_tree);
    my $result_objects = [];#リザルトobjectのリストへのリファレンス
    Matching_by_NFA($NFA,$tree,[],$result_objects);

    return $result_objects;
}


#字句解析
sub PathLexicalAnarysis{
    my ($code) = @_;#code

    @tokens = ();
    my $i = 0;
    my $sentence = 0;#連続した文字を判定するふらぐ
    my $escape = 0;
    #my $sharp = 0;#シャープ記号の連続を確認するフラグ
    while($i < length($code)){
	    my ($word) = substr($code,$i,1);

        #バックスラッシュで次のワードをエスケープ可能
        #意図的にバックスラッシュ自体をエスケープ不可能にしている
        if($word eq "\\"){
            $escape = 1;
        }elsif (($word =~ /^[a-zA-Z0-9_\w]+$/)||($escape)){
            $escape = 0;
            if($sentence){
                $tokens[$#tokens].=$word;
            }else{
                push(@tokens,$word);
                $sentence = 1;
            }
        }else{
            $sentence = 0;#ノード名の連続を終了
            if ($word eq ">"){
                push(@tokens,"\\>");
            }elsif ($word eq "|"){
                push(@tokens,"\\|");
            }elsif ($word eq "("){
                push(@tokens,"\\(");
            }elsif ($word eq ")"){
                push(@tokens,"\\)");
            }elsif ($word eq "."){
                push(@tokens,"\\.");
            }elsif ($word eq "*"){
                push(@tokens,"\\*");
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
                #スペース等
                #なにもしない
            }
        }
        
        
    	$i++;
    }
    #終端記号付与
    push(@tokens,"\\;");
    #デバッグ用出力
   # print("@tokens");

    return @tokens;
}

#構文解析
#引数:字句解析後のトークン配列
sub PathSyntaxAnalysis{
    #my ($ref) = @_;
    #my @tokens = @{$ref};

    return A();

    sub A{
        #print("\nA()--->");
        #print(@tokens);
        
        my $ret1 = B();
        my $ret2 = A_D();

        return {'type' => "A", 'val' => undef, 'elem' => [$ret1, $ret2]};
    }

    sub A_D{
        #print("\nA_D()--->");
        #print(@tokens);
        
        #大なりが来るか判定
        if ($tokens[0] eq "\\|"){
            #パイプを受理
            shift(@tokens);
            my $ret1 = B();
            my $ret2 = A_D();

            return {'type' => "A_D_|", 'val' => undef, 'elem' => [$ret1, $ret2]};
        }else{
            #イプシロン
            return {'type' => "A_D_else", 'val' => undef, 'elem' => []};
        }
        return undef;
    }

    sub B{
        #print("\nB()--->");
        #print(@tokens);
        
        my $ret1 = C();
        my $ret2 = D();
        my $ret3 = B_D();

        return {'type' => "B", 'val' => undef, 'elem' => [$ret1,$ret2,$ret3]};
    }

    sub B_D{
        #print("\nB_D()--->");
        #print(@tokens);
        
        #パイプが来るか判定
        if ($tokens[0] eq "\\>"){
            #パイプを受理
            shift(@tokens);
            my $ret1 = C();
            my $ret2 = D();
            my $ret3 = B_D();

            return {'type' => "B_D_>", 'val' => undef, 'elem' => [$ret1,$ret2,$ret3]};
        }elsif ($tokens[0] eq "\\("){
            #(を受理
            shift(@tokens);
            if ($tokens[0] eq "\\>"){
                #>を受理
                shift(@tokens);
                my $ret1 = A();
                if ($tokens[0] eq "\\)"){
                    #)を受理
                    shift(@tokens);
                    my $ret2 = D();
                    my $ret3 = B_D();
                    return {'type' => "B_D_(", 'val' => undef, 'elem' => [$ret1,$ret2,$ret3]};
                }else{
                    #)が無い場合はエラー
                    #print("!!!  ERROR     in  B_D 2   !!!");
                    die;
                }
            }else{
                #>が無い場合はエラー
                #print("!!!  ERROR     in  B_D 1   !!!");
                die;
            }
        }else{
            #イプシロン
            return {'type' => "B_D_else", 'val' => undef, 'elem' => []};
        }
        return undef;
    }

    sub C{
        #print("\nC()--->");
        #print(@tokens);
        
        #(が来るか判定
        if ($tokens[0] eq "\\("){
            #(を受理
            shift(@tokens);
            my $ret1 = A();
            if ($tokens[0] eq "\\)"){
                #)を受理
                shift(@tokens);
                return {'type' => "C_(", 'val' => undef, 'elem' => [$ret1]};
            }else{
                #)が無い場合はエラー
                #print("!!!  ERROR     in  C 1   !!!");
                die;
            }
        }else{
            #shift(@tokens);
            my $ret1 = NODE();
            return {'type' => "C_node", 'val' => undef, 'elem' => [$ret1]};
        }
        return undef;
    }


    sub D{
        #print("\nD()--->");
        #print(@tokens);
        
        if ($tokens[0] eq "\\*"){
            #*を受理
            shift(@tokens);
            return {'type' => "D_*", 'val' => undef, 'elem' => undef};
        }else{
            #いぷしろん
            return {'type' => "D_else", 'val' => undef, 'elem' => undef};
        }
    }

    sub NODE{
        #print("\nNODE()--->");
        #print(@tokens);

        #ノード名が来るか判定
        if (substr($tokens[0],0,1) ne "\\"){
            #ノード名を受理
            my $node_name = shift(@tokens);
            my $val = VAL();
            my $place = PLACE();
            return {'type' => "NODE_name", 'val' => $node_name, 'elem' => [$val,$place]};
        }elsif($tokens[0] eq "\\."){
            #.を受理
            shift(@tokens);
            my $val = VAL();
            my $place = PLACE();
            return {'type' => "NODE_dot", 'val' => undef, 'elem' => [$val,$place]};
        }elsif($tokens[0] eq "\\##"){
            ###を受理
            shift(@tokens);
            my $place_name = shift(@tokens);
            return {'type' => "NODE_place", 'val' => $place_name, 'elem' => undef};
        }else{
            die;
        }
    }

    sub VAL{
        #print("\nVAL()--->");
        #print(@tokens);

        if ($tokens[0] eq "\\#"){
            #.を受理
            shift(@tokens);
            my $ret1 = VAL_NAME();
            if (substr($tokens[0],0,1) ne "\\"){
                my $val = shift(@tokens);
                my $ret2 = VAL();
                return {'type' => "VAL", 'val' => $val, 'elem' => [$ret1,$ret2]};
            }else{
                #value名でない場合はエラー
                #print("!!!  ERROR     in  VAL   !!!");
                die;
            }
        }else{
            #イプシロン
            return {'type' => "VAL_else", 'val' => undef, 'elem' => []};
        }
        return undef;
    }

    sub VAL_NAME{
        #print("\nVAL_NAME()--->");
        #print(@tokens);

        if ($tokens[0] eq "\\{"){
            #{を受理
            shift(@tokens);
            if (substr($tokens[0],0,1) ne "\\"){
                my $val_name = shift(@tokens);
                if ($tokens[0] eq "\\}"){
                    shift(@tokens);
                    return {'type' => "VAL_NAME", 'val' => $val_name, 'elem' => []};
                }else{
                    #value名でない場合はエラー
                    #print("!!!  ERROR     in  VAL_NAME_1   !!!");
                    die;
                }
            }else{
                #value名でない場合はエラー
                #print("!!!  ERROR     in  VAL_NAME_2   !!!");
                die;
            }

        }else{
            #イプシロン
            return {'type' => "VAL_NAME_else", 'val' => undef, 'elem' => []};
        }
    }

    sub PLACE{
        #print("\nPLACE()--->");
        #print(@tokens);

        if ($tokens[0] eq "\\##"){
            ###を受理
            shift(@tokens);
            if (substr($tokens[0],0,1) ne "\\"){
                my $place_name = shift(@tokens);
                return {'type' => "PLACE", 'val' => $place_name, 'elem' => []};
            }else{
                #value名でない場合はエラー
                #print("!!!  ERROR     in  PLACE   !!!");
                die;
            }
        }else{
            #いぷしろん
            return {'type' => "PLACE_else", 'val' => undef, 'elem' => undef};
        }
    }

}

#構文木を走査して抽象構文木を返す改良版
sub MakeAbstractPathSyntaxTree_2{
    my ($node) = @_;#走査中構文木の、今見ているノード
    my @elem;#再帰走査における、複数の戻り値を格納するリスト
    my $ret;#戻り値が入る

    #ここで再帰走査している
    foreach my $child (@{$node->{elem}}) {
        my @results = MakeAbstractPathSyntaxTree_2($child);#ここで再帰
        foreach my $result (@results){
            if (defined($result)){#undefな値が無いかチェックしながら@elemに保存し直している
                push(@elem, $result);
            }else{
                push(@elem, undef);
            }
        }
    }

    #戻り値はリストで統一したい
    if ($node -> {type} eq "A"){
        if ($node -> {elem} -> [1] -> {type} eq "A_D_else"){
            $ret = $elem[0];
        }else{
            #合成
            $ret = $elem[1];
            unshift(@{$ret -> {elem}},$elem[0]);
        }
    }elsif ($node -> {type} eq "B"){
        my $c = $elem[0];
        if ($node -> {elem} -> [1] -> {type} eq "D_*"){
            #アスタリスクがある場合、アスタリスクと合成
            $c = $elem[1];
            $c -> {elem} -> [0] = $elem[0];
        }

        if ($node -> {elem} -> [2] -> {type} eq "B_D_else"){
            $ret = $c;
        }else{
            #合成
            $ret = $elem[2];
            unshift(@{$ret -> {elem}},$c);
        }
    }elsif ($node -> {type} eq "A_D_|"){
        #|の連続の終わりを判定する
        if ($node -> {elem} -> [1] -> {type} eq "A_D_else"){
            #終わりなら、| elem[0]を返す
            $ret = {'type' => "|", 'val' => undef, 'elem' => [$elem[0]]};
        }else{
            #まだ続くなら合成
            $ret = $elem[1];
            unshift(@{$ret -> {elem}},$elem[0]);
        }
    }elsif ($node -> {type} eq "B_D_>"){
        my $c = $elem[0];
        if ($node -> {elem} -> [1] -> {type} eq "D_*"){
            #アスタリスクがある場合、アスタリスクと合成
            $c = $elem[1];
            $c -> {elem} -> [0] = $elem[0];
        }

        #>の連続の終わりを判定する
        if ($node -> {elem} -> [2] -> {type} eq "B_D_else"){
            #終わりなら、> $cを返す
            $ret = {'type' => ">", 'val' => undef, 'elem' => [$c]};
        }else{
            #まだ続くなら合成
            $ret = $elem[2];
            unshift(@{$ret -> {elem}},$c);
        }
    }elsif ($node -> {type} eq "B_D_("){
        my $a = $elem[0];
        if ($node -> {elem} -> [1] -> {type} eq "D_*"){
            #アスタリスクがある場合、アスタリスクと合成
            $a = $elem[1];
            $a -> {elem} -> [0] = $elem[0];
        }

        #>の連続の終わりを判定する
        if ($node -> {elem} -> [2] -> {type} eq "B_D_else"){
            #終わりなら、> $aを返す
            $ret = {'type' => ">", 'val' => undef, 'elem' => [$a]};
        }else{
            #まだ続くなら合成
            $ret = $elem[2];
            unshift(@{$ret -> {elem}},$a);
        }
    }elsif ($node -> {type} eq "C_node"){
        $ret = $elem[0];
    }elsif ($node -> {type} eq "C_("){
        return @elem;
    }elsif ($node -> {type} eq "C_."){
        return {'type' => "dot", 'val' => undef, 'elem' => undef};
    }elsif ($node -> {type} eq "D_*"){
        return {'type' => "*", 'val' => undef, 'elem' => undef};
    }elsif ($node -> {type} eq "NODE_name"){
        $ret = {'type' => "node_name", 'val' => {'type' => $node->{val}}, 'elem' => undef};
        if ($node -> {elem} -> [0] -> {type} eq "VAL"){
            $ret->{val} = {%{$ret->{val}}, %{$elem[0]}};
        }
        if ($node -> {elem} -> [1] -> {type} eq "PLACE"){
            $ret = {%{$ret}, %{$elem[1]}};
        }
    }elsif ($node -> {type} eq "NODE_dot"){
        #ドットノード
        $ret = {'type' => "dot", 'val' => {}, 'elem' => undef};
        if ($node -> {elem} -> [0] -> {type} eq "VAL"){
            $ret->{val} = {%{$ret->{val}}, %{$elem[0]}};
        }
        if ($node -> {elem} -> [1] -> {type} eq "PLACE"){
            $ret = {%{$ret}, %{$elem[1]}};
        }
    }elsif ($node -> {type} eq "NODE_place"){
        #プレース指定
        $ret = {'type' => "place", 'val' => undef, 'elem' => undef};
        if ($node -> {elem} -> [0] -> {type} eq "VAL"){
            $ret = {%{$ret}, 'extra_values' => %{$elem[0]}};
        }
        if ($node -> {elem} -> [1] -> {type} eq "PLACE"){
            $ret = {%{$ret}, %{$elem[1]}};
        }
    }elsif ($node -> {type} eq "VAL"){
        #属性指定
        my $val_name = 'val';
        if ($node -> {elem} -> [0] -> {type} eq "VAL_NAME"){
            $val_name = $elem[0] -> {val};
        }
        $ret = {$val_name => $node->{val}};
        if ($node -> {elem} -> [1] -> {type} eq "VAL"){
            $ret = {%{$ret}, %{$elem[1]}};
        }
    }elsif ($node -> {type} eq "VAL_NAME"){
        #任意属性名
        $ret = {'val' => $node -> {val}};
    }elsif ($node -> {type} eq "PLACE"){
        #プレース名
        $ret = {'place' => $node -> {val}};
    }else{
        #通常実行されないelse。dieするのが正しい？(確認不足)
        return undef;
    }

    return $ret;
}


#抽象構文木からNFAを作成
#NFA同士を合成しながら返す
sub CreateNFA{
    my ($abstract_tree) = @_;
    my $result;

    $result = CreateNFARec($abstract_tree);
    foreach my $nfa_node (@{$result}){
        foreach my $next (@{$nfa_node}){
            if ($next->{next} == -1){
                $next->{next} = @{$result};
            }
        }
    }
    push(@{$result},[{'end' => 1}]);

    return $result;
}

#抽象構文木からNFAを作成の再帰部分
sub CreateNFARec{
    my ($node) = @_;
    my $result_nfa;#戻り値として返すnfa
    my @elem_ret;#子要素からの戻り値リスト

    #抽象構文木の走査
    foreach my $child (@{$node->{elem}}) {
        push(@elem_ret,CreateNFARec($child));
    }

    if ($node -> {type} eq "|"){
        $result_nfa = $elem_ret[0];#合成元のnfa、名前がわかりにくいのでかえたい
        for (my $i = 1; $i < @elem_ret; $i++) {
            my $next_nfa = $elem_ret[$i];#合成するnfa、、次に追加するNFA～というような名前がいい？
            my $add_val = @{$result_nfa}-1;#合成元のnfaの状態数-1。次に合成されるnfaの状態番号更新用
            #合成するnfaの全てのエッジについて、状態番号を更新する
            foreach my $nfa_node (@{$next_nfa}){
                foreach my $next (@{$nfa_node}){
                    #終端ノード(-1)へのエッジおよび開始ノード(0)へのエッジは更新しない
                    if ($next->{next} > 0){
                        $next->{next} += $add_val;
                    }
                }
            }
            #result_nfaとnext_nfaの開始ノードのエッジを統合
            push(@{$result_nfa -> [0]},@{$next_nfa -> [0]});
            #next_nfaの開始ノードを削除し、next_nfa全体をresult_nfaと結合
            shift(@{$next_nfa});#開始ノード(0)を削除
            push(@{$result_nfa},@{$next_nfa});#全体の結合
        }
    }elsif($node -> {type} eq ">"){
        $result_nfa = $elem_ret[0];
        for (my $i = 1; $i < @elem_ret; $i++) {
            my $next_nfa = $elem_ret[$i];#合成するnfa、言葉があやふや、A+B=C
            my $add_val = @{$result_nfa};#合成元のnfaの状態数。次に合成されるnfaの状態番号更新用
            #合成するnfaの全てのエッジについて、状態番号を更新する
            foreach my $nfa_node (@{$next_nfa}){
                foreach my $next (@{$nfa_node}){
                    #終端ノード(-1)へのエッジは更新しない。開始ノード(0)へのエッジは更新
                    if ($next->{next} != -1){
                        $next->{next} += $add_val;
                    }
                }
            }
            #result_nfaの終端ノードへのエッジを、next_nfaの開始ノードへのエッジに変更
            foreach my $nfa_node (@{$result_nfa}){
                foreach my $next (@{$nfa_node}){
                    #終端ノードを書き換え
                    if ($next->{next} == -1){
                        $next->{next} = $add_val;
                    }
                }
            }
            push(@{$result_nfa},@{$next_nfa});#全体の結合
        }
    }elsif($node -> {type} eq "*"){
        $result_nfa -> [0] -> [0] -> {epsilon} = 1;#イプシロンフラグを立てる
        $result_nfa -> [0] -> [0] -> {key} = undef;
        $result_nfa -> [0] -> [0] -> {next} = 1;#接続先の先頭が0→1になるため
        $result_nfa -> [0] -> [1] -> {epsilon} = 1;#イプシロンフラグを立てる
        $result_nfa -> [0] -> [1] -> {key} = undef;
        $result_nfa -> [0] -> [1] -> {next} = -1;#終端ノードへ

        #番号の振り直し
        foreach my $nfa_node (@{$elem_ret[0]}){
            foreach my $next (@{$nfa_node}){
                #終端ノード以外に1を加算して更新
                if ($next->{next} != -1){
                    $next->{next}++;
                }else{
                    #終端ノードへ向かうnextは「追加するノード番号(合成前のノード数+1)」で上書き
                    $next->{next} = @{$elem_ret[0]} + 1;
                }
            }
        }
        
        my @add_node;
        $add_node[0]->{epsilon} = 1;#イプシロンフラグを立てる
        $add_node[0]->{key} = undef;
        $add_node[0]->{next} = 1;#繰り返しの先頭に戻る
        $add_node[1]->{epsilon} = 1;#イプシロンフラグを立てる
        $add_node[1]->{key} = undef;
        $add_node[1]->{next} = -1;#終端ノードへ

        push(@{$result_nfa},(@{$elem_ret[0]}, \@add_node));#全体の結合
        
    }elsif($node -> {type} eq "dot"){
        $result_nfa -> [0] -> [0] -> {dot} = 1;#ドットフラグを立てる
        $result_nfa -> [0] -> [0] -> {key} = $node -> {val};
        ##print $node -> {val};
        $result_nfa -> [0] -> [0] -> {next} = -1;#終端ノードへ
    }elsif($node -> {type} eq "node_name"){
        $result_nfa -> [0] -> [0] -> {key} = $node -> {val};
        $result_nfa -> [0] -> [0] -> {next} = -1;#終端ノードへ
        ##print("this node is ".@{$result_nfa}."\n");
        if (exists($node -> {place})){
            #print("detect place ".$node -> {place}."\n");
            $result_nfa -> [0] -> [0] -> {place} = $node -> {place};
        }
    }else{
        #print(%{$node});
        die;
        return undef;
    }

    return $result_nfa;
}


#NFAを表として出力
sub OutputNFA{
    my ($nfa) = @_;
    my $count = 0;

    foreach my $node (@{$nfa}) {
        #print("Node:".$count."\n");
        foreach my $next (@{$node}) {
            if (exists($next->{end})){
                #print("\tEnd_node\n");
            }else{
                if (exists($next->{dot})){
                    #print("\tAny key is accepted");
                }else{
                    #print("\tKey = ");
                    if (defined($next->{key})){
                        #print(%{$next->{key}});
                    }
                }
                #print(" next = ".$next->{next}."\n");
            }
        }
        #print("\n");
        $count++;
    }
}

sub NFAMatchingJudge{
    #ノードとキーの判定
    my ($keys,$path,$path_now) = @_;

    ##print("\tkeys are ");
    ##print(%{$keys->{key}});
    ##print("\n");

    if(exists($keys -> {dot})){
        ##print "dot\n";
        ##print (%{$keys -> {key}});
    }
    foreach my $key (keys(%{$keys->{key}})) {
        my $value = $keys->{key}->{$key};
        #print("\t". $key ." value is ". $value ."\n");
        if (exists($path->[$path_now]->{$key}) && defined($path->[$path_now]->{$key}) && defined($value)){
            #print("\tpath value is ". $path->[$path_now]->{$key} ."\n");
            if (($path->[$path_now]->{$key}) eq $value){
                #print("\t\t--------------matching!!!\n");
            }else{
                #print("\t\t--------------value reject\n");
                return 0;
            }
        }else{
            #print("\t\t--------------value nothing\n");
            return 0;
        }
    }

    return 1;
}

sub NFAMatchingRec{
    my ($nfa,$path,$nfa_now,$path_now,$matched_place) = @_;
    #path_nowの値は0～@{$path}
    my $result = 0;#0は拒否、1以上は受理
    my @next;#受理された$keysのリスト。幅優先探索に使用

    if ($nfa_now == @{$nfa} - 1){
        return 0;
    }

    foreach my $keys (@{$nfa->[$nfa_now]}){
            my $nfa_end = @{$nfa} - 1;#NFAの終端まで来ているかをチェック
            my $path_end = @{$path} - 1;#PATHの終端まで来ているかをチェック

            if(exists($keys->{epsilon})){
                #イプシロンの場合の処理
                #print("\tkey is epsilon\n");
                if ($keys->{next} == $nfa_end){
                    #NFAの終端ノードに到達した
                    if(($path_now == @{$path})){
                        #パスが全て受理済みであれば、イプシロン遷移で終端ノードについた場合でもNFA受理
                        #print("\taccepted\n");
                        $result = 1;
                    }
                }else{
                    #NFA続行
                    #イプシロン遷移なのでほぼ無条件にNFAの走査を続行
                    push(@next,$keys);
                }
            }elsif($path_now > $path_end){
                #パスがすべて受理されている状態でイプシロン以外のkeyだった場合は何もしない
                #warning文よけ
            }elsif(NFAMatchingJudge($keys,$path,$path_now)){
                if (exists($keys->{dot})){
                    #print("\tdot accepted\n");
                }else{
                    #print("\tkey ". $keys->{key}->{type} ." accepted\n");
                }
                if (exists($keys->{place})){
                    #マッチしたキーがプレースなら
                    #print("matching in place !!! ".$keys->{place}."\n");
                    $matched_place -> {$keys->{place}} = @$path[$path_now];
                }
                if ($keys->{next} == $nfa_end){
                    #NFAの終端ノードに到達した
                    if(($path_now == $path_end)){
                        #パスを消化しきっていれば受理
                        #print("\taccepted\n");
                        $result = 1;
                    }else{
                        #NFAの終端ノードに到達したがパスを消化できていない場合
                        #$result = 0のままであればいいのでなにもしない
                    }
                }else{
                    #NFA続行
                    push(@next,$keys);
                    #$result += NFAMatchingRec($nfa,$path,$keys->{next},$path_now + 1);
                }
            }else{
                #print("\tkey rejected.\n");
            }
    }

    #マッチ済み($resultが1)なら以後の走査は不要
    if ($result > 0){
        return $result;
    }else{
        #幅優先でNFAを走査
        foreach my $keys (@next){
            if (exists($keys->{epsilon})){
                $result += NFAMatchingRec($nfa,$path,$keys->{next},$path_now,$matched_place);
            }else{
                $result += NFAMatchingRec($nfa,$path,$keys->{next},$path_now + 1,$matched_place);
            }
        }
    }

    return $result;
}

#NFAマッチング
#NFA
sub NFA_matching{
    my ($nfa,$path,$result_obj) = @_;
    my $matching_count = 0;
    my $path_end = @{$path} - 1;

    foreach (0..$path_end){
        #パスを先頭からずらしながらNFAマッチングする
        #resultはNFAが受理した回数
        my $returned_places = {};#NFAMatchingRecの戻り値(placeのマッチ個所)
        my $result = NFAMatchingRec($nfa,$path,0,$_,$returned_places);
        if($result){
            $matching_count += $result;
            $result_obj -> place($returned_places);
        }
    }
    
    #print("\t\t\tresult = ".$matching_count);
    if ($matching_count){
        #print("\tNFA accept ");
        foreach my $i (@{$path}){
            #print(" / ".$i->{type});
        }
        #print("\n");
        return 1;
    }else{
        #print("\tNFA reject.\n");
        return 0;
    }
}

#木内の全パスを網羅し、NFAマッチング
sub Matching_by_NFA{
    my ($nfa,$tree,$path,$result_objects) = @_;
    my @new_path = @{$path};
    push(@new_path,$tree);
    #print("now_path = ");
    foreach my $i (@new_path){
        #print(" / ".$i->{type});
    }
    #print("\n");

    my $result_obj = PathMatchingObject -> new;
    #NFAがパスを受理するか確認
    if (NFA_matching($nfa,\@new_path,$result_obj)){
        #受理されたらresult_objectsに追加
        #ここで追加するとplace等を登録しづらいため、後に更新
        $result_obj -> tail($new_path[-1]);
        push(@{$result_objects},$result_obj);
    }

    foreach my $child (@{$tree->{elem}}){
        Matching_by_NFA($nfa,$child,\@new_path,$result_objects);
    }
}

#以下は実験用関数
#いずれ消去されると思われる



1;