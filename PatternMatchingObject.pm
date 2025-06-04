use strict;
use warnings;

package PatternMatchingObject;

#コンストラクタ
sub new {
  my ($class, %args) = @_;#パッケージ(クラス)名と引数
  my $self = {%args};#データ
  return bless $self, $class;
}

#属性headのアクセッサ
sub head{
  my $self = shift;
  if (@_) {
    $self->{head} = $_[0];
  }
  return $self->{head};
}

#属性captureのアクセッサ
#$self->{capture}キーに、引数のハッシュを追加していく
sub capture{
  my $self = shift;

  if (@_) {
    $self->{capture} = $_[0];
  }
  return $self->{capture};
}

sub printTest{
    print("object test\n");
}


1;