package TreePatternMatching;

use Exporter;
@ISA = (Exporter);
@EXPORT = qw(TreePatternMatching);

use PatternMatchingObject;

use utf8;
use strict;
use warnings;

use lib qw(./);
use Parse_Lex;

#elemが定義なし、elem = undef、elem -> []のどれかならfalseを返す
sub HasElemChild ($)
{return (exists $_[0]->{elem} && defined $_[0]->{elem} &&  @{$_[0]->{elem}}>0);}

sub TreePatternMatching{
    my($code,$tree) = @_;

    my $syntax_tree = Parse_Lex::parse($code);
    my $abst_tree = MakeAbstractPatternSyntaxTree($syntax_tree,[]);
    my $match_results = PatternMatching($tree,$abst_tree);
    
    return $match_results;
}

#抽象構文木生成
#labels_nameは無名リストへのリファレンスで、認識するラベル名をいれる
sub MakeAbstractPatternSyntaxTree{
    my ($node, $labels_name) = @_;
    my @elem;
    my $ret;
    my @results;
    my $new_labels_name = [@$labels_name];

    foreach my $child (@{$node->{elem}}) {
        @results = MakeAbstractPatternSyntaxTree($child, $new_labels_name);
        foreach my $result (@results){
            if (defined($result)){#grepできれいにかける？？
                push(@elem, $result);
            }else{
                push(@elem, undef);
            }
        }
        #NT:_label:1だった場合、再帰する前にラベル名だけ登録しておく(再帰内に伝達する必要があるため)
        if (($node -> {type} eq "NT:_label:1")&&($child -> {type} eq "IDENTIFIER")){
            #ラベル付き再帰サブツリー
            push(@$new_labels_name, $elem[0]);
        }
    }
    
    if ($node -> {type} eq "NT:family:1"){
        #>で接続された親子
        if ($node->{elem}->[2] -> {type} ne 'NT:family:1'){
            push(@{$elem[0]->{elem}},$elem[2]);
            $ret = $elem[0]; 
        }else{
            #連続した>の合成
            push(@{$elem[0]->{elem}},$elem[2]);
            $ret = $elem[0]; 
        }
    }elsif ($node -> {type} eq "NT:family:2"){
        #,で接続された兄弟
        if ($node->{elem}->[1] -> {type} ne 'NT:family:2'){
            $ret = {'type' => 'sequence', 'elem' => [$elem[0],$elem[1]]};
        }else{
            #合成
            unshift(@{$elem[1] -> {elem}},$elem[0]);
            $ret = $elem[1];
        }
    }elsif ($node -> {type} eq "NT:select:1"){
        #|で接続された兄弟
        if ($node->{elem}->[0] -> {type} ne 'NT:select:1'){
            $ret = {'type' => '|', 'elem' => [$elem[0],$elem[2]]};
        }else{
            #合成
            unshift(@{$elem[0] ->{elem}},$elem[2]);
            $ret = $elem[0];
        }
    }elsif ($node -> {type} eq "NT:_label:1"){
        #ラベル付き再帰サブツリー
        $ret = {'type' => 'LABEL', 'val' => $elem[0] ,'elem' => [$elem[2]]};
    }elsif ($node -> {type} eq "NT:_label:3"){
        #ラベル付き再帰サブツリー
        $ret = {'type' => 'JUMPto()', 'val' => $node -> {elem} -> [2] -> {val} ,'elem' => []};
    }elsif ($node -> {type} eq "NT:pre_node:1"){
        #( )で括られている準ノード群
        #そのまま返せばOK？
        #$ret = $elem[1];
        #変更
        $ret = {'type' => '()', 'val' => undef ,'elem' => [$elem[1]]};
    }elsif ($node -> {type} eq "NT:pre_node_option:1"){
        #- NT:pre_node_option_2 となるようなオプション付き準ノード
        #重複マッチを許可(これ以下のサブツリーは走査から除外しない)
        $elem[1] -> {accept_overlap} = 1;
        $ret = $elem[1];
    }elsif ($node -> {type} eq "NT:pre_node_option:2"){
        #NT:pre_node_option_2 $となるようなオプション付き準ノード
        #兄弟の末っ子が条件
        $elem[0] -> {youngest_only} = 1;
        $ret = $elem[0];
    }elsif ($node -> {type} eq "NT:pre_node_option:3"){
        #- NT:pre_node_option_2 $となるようなオプション付き準ノード
        $elem[1] -> {accept_overlap} = 1;
        $elem[1] -> {youngest_only} = 1;
        $ret = $elem[1];
    }elsif ($node -> {type} eq "NT:pre_node_option_2:1"){
        #! pre_nodeとなるようなオプション付き準ノード
        $elem[1] -> {denial} = 1;
        $ret = $elem[1];
    }elsif ($node -> {type} eq "NT:node:1"){
        #
        if (grep($_ eq ($elem[0]), @{$labels_name})){
            #ラベル名
            return {'type' => 'LABEL_NAME', 'val' => $elem[0]};
        }else{
            #ノード名
            return {'type' => 'NODE', 'val' => $elem[0]};
        }
    }elsif ($node -> {type} eq "NT:node:2"){
        #
        return {'type' => 'NODE', 'val' => $elem[0], 'values' => $elem[1]};
    }elsif ($node -> {type} eq "NT:node:3"){
        #
        return $elem[0];
    }elsif ($node -> {type} eq "NT:node:4"){
        #キャプチャつきノード
        #ノード名
        $ret = {'type' => 'NODE', 'val' => $elem[0]};
        $ret -> {capture} = $elem[1] -> {val};
        #print("place is ". $elem[1] -> {val});
    }elsif ($node -> {type} eq "IDENTIFIER"){
        return $node -> {val};#ハッシュではなくval値の文字列を直接返している(あんまり良くない)
    }elsif ($node -> {type} eq "NT:type_name:1"){
        # ドット (.) だった場合
        return {'type' => 'NODE', 'val' => "this is dot" , 'dot' => 1};
    }elsif ($node -> {type} eq "NT:val_rep:1"){
        #value連続
        return {$elem[0],$elem[1]};
    }elsif ($node -> {type} eq "NT:val_rep:2"){
        #value単独
        return $elem[0];
    }elsif ($node -> {type} eq "NT:val:1"){
        return {$elem[2] => $elem[4]};
    }elsif ($node -> {type} eq "NT:val:2"){
        return {"val" => $elem[1]};
    }elsif ($node -> {type} eq "NT:place:1"){
        # capture だった場合キャプチャ名を返す
        return {'type' => 'CAP', 'val' => $elem[1]};
    }else{
        return $elem[0];
    }

    return $ret;
}

#呼び出し
sub PatternMatching{
    my ($tree, $abst_tree) = @_;

    #仮に最後にマッチした位置の全体木のノードを返す
    return PatternMatching_Traverse_2($tree, $abst_tree);
}

#全体木の走査
#順次探索ようの仮セッチ
sub PatternMatching_Traverse_2{
    my ($tree, $abst_tree) = @_;
    my $node = $tree;
    my @search_list;
    my $results = [];#一致したパターンごとのオブジェクトのリスト
    
    push(@search_list,$node);
    #深さ優先探索
    #本当はstack+queue法でやる
    while(@search_list){
        $node = pop(@search_list);
        #print("-------------start---------------\n");
        my $captures = {};#取得したキャプチャ
        my $ret = PatternMatching_Apply_2($node, $abst_tree, $captures);
        #print("\n");

        if ($ret){
            #print("\t\t!!!Matching!!! ".$node->{type}." : ".$node->{val});
            foreach my $next (@{$ret}){
                #print($next -> {type}." / ".$next -> {val}." ");
                push(@search_list,$next);
            }
            #print("\n---captures----\n");
            for my $cap (sort keys %$captures) {
                #print "$cap =". $captures -> {$cap} -> {type}." : ";
                #print $captures -> {$cap} -> {val}."\n";
            }
            #print("---------------\n");
            my $result_obj = PatternMatchingObject -> new;
            $result_obj -> head($node);
            $result_obj -> capture($captures);
            push(@{$results},$result_obj);
        }else{
            #print("\tFailed." . $node->{type} . "\n");
            
            foreach my $child (reverse(@{$node -> {elem}})){
                push(@search_list,$child);
            }
        }

        #print("-------------end---------------\n");

    }

    return $results;

}

#バリュー条件が一致したかどうかを判定する
sub JudgeValuesMatching{
    my ($abst, $tree) = @_;

    if (exists($abst -> {values})){
        foreach my $key (keys(%{$abst -> {values}})){
            if (exists($tree -> {$key})){
                if (($abst -> {values} -> {$key}) eq ($tree -> {$key})){
                    #一致した場合は何もしない
                }else{
                    return 0;
                }
                #全て一致していたら真
                return 1;
            }else{
                return 0;
            }
        }
    }else{
        return 1;
    }

}

#ノード条件が一致したかどうかを判定する
sub JudgeNodeMatching{
    my ($abst, $tree, $youngest) = @_;
    my $ret = 0;

    if(((exists($abst -> {dot})) && (defined($tree -> {type})))){
        #ドット
        $ret = JudgeValuesMatching($abst, $tree);
    }elsif (($abst -> {val}) eq ($tree -> {type})){
        #通常のマッチ
        $ret = JudgeValuesMatching($abst, $tree);
    }
    
    if ((exists($abst -> {denial}))){
        #否定
        $ret = !$ret;
    }

    if ((exists($abst -> {youngest_only}))){
        #末端ノード
        if (!$youngest){
            $ret = 0;
        }
    }

    return $ret;
        
}

#パターン2
#アブストラクトツリーを走査し、全体木との一致をみる
sub PatternMatching_Apply_2{
    my ($subtree, $abst_tree, $captures) = @_;
    my $tree_node = $subtree;
    my $abst_node = $abst_tree;
    my $abst_now;
    my $tree_now;
    my @tree_search;#部分木走査ようスタック+キュー
    my @abst_search;#抽象構文木走査ようスタック+キュー
    my @branch_stack;#選択などでの失敗時の復帰個所スタック
    my %label_stack;#再帰先のラベルスタック
    my @parentheses_stack;#再帰先の括弧スタック
    my @next_traverse;#除外マッチング時に、次の走査対象となりうるノード群
    my $accept_overlap = 0;#連続した重複許可を判定する変数
    
    push(@tree_search,{"node" => $tree_node, "iterator" => "0", "youngest" => "1"});
    push(@abst_search,{"node" => $abst_node, "iterator" => "0"});

    @parentheses_stack=($abst_now);#括弧指定で再帰する場合に、全体を囲う括弧を無条件で積む

    #深さ優先探索
    while(@abst_search){
        #最後に積まれたabst_searchを読む
        if (@abst_search){
            $abst_now = $abst_search[-1];
        }
        if (@tree_search){
            $tree_now = $tree_search[-1];
        }
        
        if ($abst_now -> {node} -> {type} eq "sequence"){
            #print("seq\n");
            if ($abst_now -> {iterator} >= @{$abst_now -> {node} -> {elem}}){
                #全子要素を走査したら自身をpop
                pop(@abst_search);
            }else{
                #子供がいれば積む
                if (exists($abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}])){
                    #print("seq tsunda ". $abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}]->{val} . "\n");
                    push(@abst_search, {"node" => $abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}], "iterator" => "0"});
                    $abst_now -> {iterator}++;
                    #print("this is tree iterator ". $tree_now -> {iterator}. "\n");
                    #木の走査
                    if (exists($tree_now -> {node} -> {elem} -> [$tree_now -> {iterator}])){
                        #print("tree is ". $tree_now -> {node} -> {elem} -> [$tree_now -> {iterator}]->{type});
                        push(@tree_search, {"node" => $tree_now -> {node} -> {elem} -> [$tree_now -> {iterator}], "iterator" => "0"});
                        $tree_now -> {iterator}++;
                        if ($tree_now -> {iterator} >= @{$tree_now -> {node} -> {elem}}){
                            #最後の要素ならyoungestフラグを建てる
                            $tree_search[-1] -> {youngest} = "1";
                            #printf($tree_search[-1] -> {node} -> {type}." is youngest.");
                        }
                    }else{
                        #エラー？走査木の兄弟よりシーケンスの兄弟数が多い
                        #print("seq mou kiga nai\n");
                        #print("sequence rejeted.\n");
                        if (@branch_stack){
                            @abst_search = @{$branch_stack[-1] -> {abst_stack}};
                            @tree_search = @{$branch_stack[-1] -> {tree_stack}};
                            @next_traverse = @{$branch_stack[-1] -> {next_list}};
                            $branch_stack[-1] -> {reject}++;#多分必須？？
                        }else{
                            return undef;
                        }
                    }
                }
            }
        }elsif($abst_now -> {node} -> {type} eq "|"){
            #pipeなら
            #print("it is pipe\n");
            if ($abst_now -> {iterator} == 0){
                #イテレータ0なら初期化処理
                my @new_tree_search;
                foreach my $node_data (@tree_search){
                    push(@new_tree_search,{%{$node_data}});
                }
                push(@branch_stack, { "abst_stack" => [@abst_search], "tree_stack" => [@new_tree_search], "next_list" => [@next_traverse]});
            }
            if ($abst_now -> {iterator} >= @{$abst_now -> {node} -> {elem}}){
                #全子要素を走査したら自身をpop
                if ($branch_stack[-1] -> {reject} < @{$abst_now -> {node} -> {elem}}){
                    #受理
                    #print("pipe jyuri\n");
                    pop(@abst_search);
                    pop(@branch_stack);
                }else{
                    #print("pipe rejeted.\n");
                    pop(@branch_stack);#自分を消す
                    if (@branch_stack){
                        @abst_search = @{$branch_stack[-1] -> {abst_stack}};
                        @tree_search = @{$branch_stack[-1] -> {tree_stack}};
                        @next_traverse = @{$branch_stack[-1] -> {next_list}};
                        $branch_stack[-1] -> {reject}++;#多分必須？？
                    }else{
                        return undef;
                    }
                }
            }else{
                #子を積む
                push(@abst_search, {"node" => $abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}], "iterator" => "0"});
                $abst_now -> {iterator}++;
            }

        }elsif($abst_now -> {node} -> {type} eq "LABEL"){
            #LABELだった場合、label_stackにラベル名のキーで再帰先を記録
            #print("it is LABEL\n");
            my $label_name = $abst_now -> {node} -> {val};
            #print($label_name. "  <=== kore ga label mei\n");
            $label_stack{$label_name} = $abst_now -> {node} -> {elem} -> [0];#再帰元までのジャンプ先を記録
            #print($abst_now -> {node} -> {elem} -> [0] -> {type} . " <===kokowo kiroku.\n");
            #print("$label_name is". $label_stack{$label_name}->{type} . "\n");
            #記録が終わったら自身をpopし子を積む
            pop(@abst_search);#自分をpop
            push(@abst_search, {"node" => $abst_now -> {node} -> {elem} -> [0], "iterator" => "0"});
        }elsif($abst_now -> {node} -> {type} eq "()"){
            #()だった場合、parentheses_stackに再帰先を積む
            #本当は()終了時にpopが必要(mada
            #print("it is ()\n");
            push(@parentheses_stack, $abst_now -> {node});#再帰元までのジャンプ先を記録
            #print($abst_now -> {node} -> {elem} -> [0] -> {type} . " <===kokowo kiroku.\n");
            #記録が終わったら自身をpopし子を積む
            pop(@abst_search);#自分をpop
            push(@abst_search, {"node" => $abst_now -> {node} -> {elem} -> [0], "iterator" => "0"});
        }elsif($abst_now -> {node} -> {type} eq "LABEL_NAME"){
            #ラベル名だった場合は該当ラベルまで再帰する
            my $node_name = $abst_now -> {node} -> {val};
            my $recursion_root = $label_stack{$node_name};
            #print ("JUMP to $node_name!\n");
            #print($recursion_root -> {val}. "  <=== kokohetobu\n");
            pop(@abst_search);
            push(@abst_search, {"node" => $recursion_root, "iterator" => "0"});
        }elsif($abst_now -> {node} -> {type} eq "JUMPto()"){
            #?-自然数　だった場合に括弧へ再帰する
            my $number = $abst_now -> {node} -> {val};#再帰したい括弧までの数
            my $length = @parentheses_stack - 1;#要素番号として使いたいので-1
            if ($number >= $length){
                die("Error recusion number is too big.");
            }
            my $jumpto = $parentheses_stack[$length - $number];
            #print($jumpto -> {type}. "  <=== kokohetobu$number $length\n");
            pop(@abst_search);
            push(@abst_search, {"node" => $jumpto, "iterator" => "0"});
        }else{
            #node
            #ノード名だった場合
            #print("node\n");

            if ($abst_now -> {iterator} >= 1){
                #全子要素を走査したら自身をpop
                #ノードの子は1個なので1以上なら～という条件
                pop(@abst_search);
                pop(@tree_search);

            
                #走査中木ノードを次回の走査対象から除去
                #重複許可が出ていないサブツリーのみ
                if ($accept_overlap == 0){
                    @next_traverse = grep ($_ ne ($tree_now -> {node}), @next_traverse);
                }

                #サブツリーを出たら重複許可を解除
                if (exists($abst_now -> {node}->{accept_overlap})){
                    $accept_overlap--;
                }

            }elsif (JudgeNodeMatching($abst_now -> {node}, $tree_now -> {node}, exists($tree_now -> {youngest}))){
                #ノード一致
                #print("icchi node\n");
                #print(($abst_now -> {node} -> {val}) ." vs ". ($tree_now -> {node} -> {type}));

                #キャプチャ発見
                if (exists($abst_now -> {node}->{capture})){
                    #print($abst_now -> {node}->{capture}." detected.\n");
                    my $capture_name = $abst_now -> {node} -> {capture};
                    $captures -> {$capture_name} = $tree_now -> {node};#キャプチャ名 = 一致した木ノード代入
                }

                if (exists($abst_now -> {node}->{accept_overlap})){
                    #重複許可フラグ加算。1以上なら許可される
                    $accept_overlap++;
                }
                
                #次の走査候補ノードを積む
                #重複許可が出ていないサブツリーのみ
                if ($accept_overlap == 0){
                    push(@next_traverse, @{$tree_now -> {node} -> {elem}});
                    #print("tsumunda!\n\n")
                }else{
                    #print("tsumanai\n\n");
                }
                
                #子供がいれば積む
                if (exists($abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}])){
                    #print ("me " .$abst_now -> {node} -> {val}. "is.\n");
                    push(@abst_search, {"node" => $abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}], "iterator" => "0"});

                    #木の走査
                    #！シーケンスをはさま
                    if (($abst_now -> {node} -> {elem} -> [$abst_now -> {iterator}]) -> {type} ne "sequence"){
                        #print("this is tree iterator ". $tree_now -> {iterator}. "\n");
                        if (exists($tree_now -> {node} -> {elem} -> [$tree_now -> {iterator}])){
                            #print("node kodomo\n");
                            push(@tree_search, {"node" => $tree_now -> {node} -> {elem} -> [$tree_now -> {iterator}], "iterator" => "0"});
                            $tree_now -> {iterator}++;
                        }else{
                            #エラー？積むべき走査木ノードがない
                            #print("node mou kiga nai\n");
                            #print("node rejeted.\n");
                            if (@branch_stack){
                                @abst_search = @{$branch_stack[-1] -> {abst_stack}};
                                @tree_search = @{$branch_stack[-1] -> {tree_stack}};
                                @next_traverse = @{$branch_stack[-1] -> {next_list}};
                                $branch_stack[-1] -> {reject}++;#多分必須？？
                            }else{
                                return undef;
                            }
                        }
                    }else{
                        #print("-----else-----\n");
                    }
                }
                $abst_now -> {iterator}++;
            }else{
                #print("reject node\n");
                #print(($abst_now -> {node} -> {val}) ." vs ". ($tree_now -> {node} -> {type}));
                if (@branch_stack){
                    @abst_search = @{$branch_stack[-1] -> {abst_stack}};
                    @tree_search = @{$branch_stack[-1] -> {tree_stack}};
                    @next_traverse = @{$branch_stack[-1] -> {next_list}};
                    $branch_stack[-1] -> {reject}++;
                    #print("reject now = ".$branch_stack[-1] -> {reject}. "\n");
                }else{
                    return undef;
                }
            }

        }
        ##print("kore --->");
        ##print(@next_traverse);
    }


    return [@next_traverse];
    ##print("\n");
}


1;