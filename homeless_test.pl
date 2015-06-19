#!/usr/bin/env perl
use MongoDB;
use feature 'say';
use Data::Dumper;
use DateTime::Tiny;
use Encode;

# init global MongoDB variables
my $client = MongoDB::MongoClient->new;
$client->dt_type( 'DateTime::Tiny' );
my $db = $client->get_database('BaoBeiHuiJia');
my $cl = $db->get_collection('homeless_children');
my $time = DateTime::Tiny->from_string("2015-05-10T07:14:01");

#my $result = $cl->find_one;
#my $result = $cl->find_one({'姓 名' => qr/杨文杰/});
#my $results = $cl->find({decode_utf8('姓 名') => decode_utf8('杨文杰')});
my $results = $cl->find({})->sort({decode_utf8('注册时间')=>-1})->limit(1);
#my $results = $cl->find({decode_utf8('失踪时间') => {'$gt' => $time}})->sort({decode_utf8('出生日期')=>1});
#my $results = $cl->find({decode_utf8('失踪时间') => {'$gt' => "2015-05-10T07:14:01"}})->sort({decode_utf8('出生日期')=>1});
say "total docs: " . $results->count;
while (my $doc = $results->next) {
	while (($key, $value) = each %$doc) {
		$key = encode_utf8($key);
		$value = encode_utf8($value);
		next if $key =~ /image/;
		say "$key ==== $value";
	}
}
