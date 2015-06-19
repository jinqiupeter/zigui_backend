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
my $cl = $db->get_collection('images');

my $results = $cl->find({})->limit(1);
say "total docs: " . $results->count;
while (my $doc = $results->next) {
	while (($key, $value) = each %$doc) {
		$key = encode_utf8($key);
		$value = encode_utf8($value);
		say "$key ==== $value";
	}
}
