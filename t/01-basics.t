
use strict;
use warnings;
no  warnings 'uninitialized';

use Serializer qw(thaw freeze);
use Test::More tests => 17;

sub tst ($$)  {
    my $frozen = freeze ($_[0]);
    my $unfrozen = thaw ($frozen);
    
    is_deeply $_[0], $unfrozen, "freeze/unfreeze $_[1]";

    # use Data::Dumper; print Dumper $unfrozen; print "\n";
    # use Devel::Peek; Dump $unfrozen;
}

tst ("foo", "scalar");
tst ("", "empty string");
tst (\"", "ref to an empty string");
tst (\\"", "ref to ref to an empty string");

my $tmp = "fooutf8"; utf8::upgrade ($tmp);
tst ($tmp, "utf8 scalar");

tst ([], "empty arrayref");
tst ({}, "empty hashref");
tst (\[], "ref to empty arrayref");
tst (\{}, "ref to empty hashref");
tst (\\[], "ref to ref to empty arrayref");

tst (["foo"], "arrayref with a single scalar");
tst ([""], "arrayref with a single empty scalar");
tst (["foo", "bar", "baz"], "arrayref with three scalars");

tst ({"foo" => "bar"}, "hashref with a single pair");
tst ({"" => ""}, "hashref with a single empty pair");
tst ({"foo" => 1, "bar" => "baz"}, "hashref with two pairs");

tst ([123, { a => "b", qwer => [\"asdf", "zxcv"], c => "def" }, 
      456, -100000000000000, ["xxx", "yyyyyyyyy", ] , 789, "foo", "bar"], 
     "complex structure");




