use strict;
use warnings;

package PathMatchingObject;

#コンストラクタ
sub new {
  my ($class, %args) = @_;#パッケージ(クラス)名と引数
  my $self = {%args};#データ
  return bless $self, $class;
}

#属性tailのアクセッサ
sub tail{
  my $self = shift;
  if (@_) {
    $self->{tail} = $_[0];
  }
  return $self->{tail};
}

#属性placeのアクセッサ
#$self->{place}キーに、引数のハッシュを追加していく
sub place{
  my $self = shift;

  if (@_) {
    $self->{place} = $_[0];
  }
  return $self->{place};
}

sub printTest{
    print("object test\n");
}


1;