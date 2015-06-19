#!/usr/bin/env perl
use strict;
use Mojo::UserAgent;
use MongoDB;
use DateTime::Tiny;
use MIME::Base64;
use feature 'say';
use Encode;
use Data::GUID;
binmode STDOUT, ":encoding(UTF-8)";

# baobeihuijia base url
my $bbhj = 'http://www.baobeihuijia.com';

# init global Mojo::UserAgent
my $ua = Mojo::UserAgent->new;

# init global MongoDB variables
my $client = MongoDB::MongoClient->new;
$client->dt_type( 'DateTime::Tiny' );
my $db = $client->get_database('BaoBeiHuiJia');
my $homeless_children = $db->get_collection('homeless_children');
my $image_collection = $db->get_collection('images');
$homeless_children->remove({}) if $ARGV[0] =~ /delete/i;
$image_collection->remove({}) if $ARGV[1] =~ /delete/i;
my $tid = 3;
$MongoDB::BSON::looks_like_number = 1; # force the driver to automatically convert "123" to 123

my $colon = decode_utf8('：');

#start to scrape
iterate_all_pages();
sub iterate_all_pages
{
	# get total page number
	# children looking for home url
	my $c4h_list_url = "$bbhj/list.aspx?tid=$tid&page=1";
	my $tx = $ua->get($c4h_list_url);
	my $last_page_url = $tx->res->dom->at('.pe-page2 > div > .nxt')->{href};
	$last_page_url =~ /\&page=(\d+)/;
	my $total_page = $1;
	say "total page: $total_page";

	for my $page_num (1 .. $total_page) {
		my $page_url = "$bbhj/list.aspx?tid=$tid&page=$page_num";
		say "getting $page_url ...";
		$tx = $ua->get($page_url);
		for my $child ($tx->res->dom->find('.pic_bot > div > dl > dt > a')->each) {
			fetch_detail($child->{href});
		}
	}
}

sub fetch_detail 
{
	my $detail_url = shift;
	my $full_url = "$bbhj/$detail_url";
	my %info;

	say "getting $full_url ...";
	my $tx = $ua->get($full_url);

	# extract image
	my $has_img = undef;
	my $img_data = "";
	my $img_guid = "";
	my $img_url = $tx->res->dom->at('.cimg')->{src};
	if ($img_url !~ /\/photo\/none-\d+-\d+\.jpg/) {
		$has_img = 1;
		say "downloading image at $bbhj/$img_url ...";
		$img_data = encode_base64($ua->get("$bbhj/$img_url")->res->content->asset->slurp);

		# guid used to identify the image
		my $guid = Data::GUID->new;
		$img_guid = $guid->as_string;
	}
	$info{image} = $has_img ? $img_guid : "";

	# extract all other registered info
	$tx->res->dom->find('.reginfo > ul > li')->each (
		sub {
			my $key = $_->at('span')->text;
			$key =~ s/$colon|\s+//g; # remove the utf-8 colon and space
			my $value = $_->text ? $_->text : ($_->at('a') ? $_->at('a')->text : "");
			if ($value =~ /(\d{4}).*?(\d{2}).*?(\d{2})(.*)/) {
				my $date_format = "$1-$2-$3";
				my ($h, $m, $s);
				$h = $m = $s = "00";
				if (defined $4 and $4 =~ /(\d{2}):(\d{2}):(\d{2})/) {
					$h = $1;
					$m = $2;
					$s = $3;
				}
				my $time = DateTime::Tiny->from_string( "${date_format}T$h:$m:$s" );
				$value = $time;
			}
			$info{$key} = $value;
		}
	);
	
	# insert into database
	$homeless_children->insert(\%info);
	if ($has_img) {
		my %hash = (guid => $img_guid, data => $img_data);
		$image_collection->insert(\%hash);
	}
}
