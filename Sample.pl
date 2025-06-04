use utf8;
use strict;
use warnings;

use lib qw(./);

use TreePatternMatching;
use PathPatternMatching;
use TreeConstruction;


print("### Construct Tree ###\n");
my $code = <STDIN>;
my $tree = TreeConstruction($code);

print("### Output Tree ###\n");

OutputTree($tree -> {tree});

#ここからパスパターンマッチング

print("\n### PathPatternMatching ###\n");
print("### Output Target Tree ###\n");

OutputTree(SampleTree());

##ここにパスマッチングようのコード
$code = "C > C > C";
##
my $results = PathPatternMatching($code, SampleTree());

print("### Output Results ###\n");
foreach my $res (@{$results}){
    OutputTree($res -> {tail});
}

#ここからツリーパターンマッチング

print("\n### TreePatternMatching ###\n");

##ここにツリーマッチングようのコード
$code = <STDIN>;
##
my $res = TreePatternMatching($code, SampleTree());

print("### Output Results ###\n");
foreach my $re (@{$res}){
    OutputTree($re -> {head});
    
    while (my ($key, $value) = each(%{$re->{capture}})){
        print "key=$key\n";
        OutputTree($value);
    }
}



##############################################
#木の出力
##############################################

#木出力ツール
sub OutputTree{
    my ($hash_ref,@layer) = @_;
    my %hash = %{$hash_ref};#デリファレンス
    my $type = $hash{'type'};
    my $elem = $hash{'elem'};
    my $val = $hash{'val'};
    my $layer_size = @layer;

    #ノードの情報を表示
    for (my $i = 0;$i < $layer_size;$i++){
        if ($i == ($layer_size - 1)){
            print("\t |------");
        }elsif($layer[$i]){
            print("\t |");
        }else{
            print("\t");
        }
    }
    print("[$layer_size] $type : ");
    if ($val){
        print("$val");
    }
    #print "[HasChild]\n" if HasElemChild \%hash;
    print("\n");
    push(@layer,1);

    my $count = 0;
    foreach my $child (@{$hash{'elem'}}) {
        my $children_size = @{$hash{'elem'}};
        $children_size--;#なぜ？
        if ($count == $children_size){
            pop(@layer);
            push(@layer,0);
        }
        if ($child){
            OutputTree($child,@layer);
        }
        $count++;
    }
}

##############################################

##############################################
#木構造サンプル
##############################################

sub SampleTree{
    my $nodeA = {"type" => "A", "val" => "aaa", "elem" => []};
    my $nodeB = {"type" => "B", "val" => "bbb", "elem" => []};
    my $nodeC = {"type" => "C", "val" => "ccc", "elem" => []};
    my $nodeD = {"type" => "D", "val" => "ddd", "elem" => []};
    my $nodeE = {"type" => "E", "val" => "eee", "elem" => []};
    my $nodeF = {"type" => "F", "val" => "fff", "elem" => []};
    my $nodeA2 = {"type" => "A", "val" => "aaa2", "elem" => []};
    my $nodeB2 = {"type" => "B", "val" => "bbb2", "elem" => []};
    my $nodeA3 = {"type" => "A", "val" => "aaa3", "elem" => []};
    my $nodeB3 = {"type" => "B", "val" => "bbb3", "elem" => []};
    my $nodeC2 = {"type" => "C", "val" => "ccc2", "elem" => []};
    my $nodeC3 = {"type" => "C", "val" => "ccc3", "elem" => []};
    my $nodeC4 = {"type" => "C", "val" => "ccc4", "elem" => []};
    my $nodeC5 = {"type" => "C", "val" => "ccc5", "elem" => []};
    my $nodeC6 = {"type" => "C", "val" => "ccc6", "elem" => []};
    my $nodeE2 = {"type" => "E", "val" => "eee2", "elem" => []};

    $nodeA -> {elem} = [$nodeB,$nodeC,$nodeA2];
    $nodeB -> {elem} = [$nodeD];
    $nodeC -> {elem} = [$nodeE,$nodeF];
    $nodeA2 -> {elem} = [$nodeB2,$nodeA3];
    $nodeA3 -> {elem} = [$nodeB3,$nodeC2];
    $nodeC2 -> {elem} = [$nodeC3];
    $nodeC3 -> {elem} = [$nodeC4];
    $nodeC4 -> {elem} = [$nodeC5];
    $nodeC5 -> {elem} = [$nodeC6];
    $nodeC6 -> {elem} = [$nodeE2];

    return $nodeA;
}


##############################################

