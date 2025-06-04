use strict;
use warnings;

package TreeObject;

#コンストラクタ
sub new {
  my ($class, %args) = @_;#パッケージ(クラス)名と引数
  my $self = {%args};#データ
  return bless $self, $class;
}

#属性treeのアクセッサ(root?)
sub tree{
  my $self = shift;
  if (@_) {
    $self->{tree} = $_[0];
  }
  return $self->{tree};
}

#属性placeのアクセッサ
sub place{
  my $self = shift;

  if (@_) {
    $self->{place} = $_[0];
  }
  return $self->{place};
}

#属性edgeのアクセッサ
sub edge{
  my $self = shift;

  if (@_) {
    $self->{edge} = $_[0];
  }
  return $self->{edge};
}

#edgeの再接続
#第一引数：プレース名　第二引数：再接続先のノードリファレンス
sub reconnectEdge{
  my $self = shift;

  if (@_) {
    my $parent = @{$self->{edge}->{$_[0]}}[0];
    my $number = @{$self->{edge}->{$_[0]}}[1];
    #$parent -> {elem}
    print("parent is ".$parent -> {type}."\n");
    print("number is ".$number."\n");
    print("new node is ".$_[1] -> {type}."\n");
    @{$parent -> {elem}}[$number] = $_[1];
  }
  return 0;
  #return $self->{edge};
}

sub printTest{
    print("object test\n");
}


1;