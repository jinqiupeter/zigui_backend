package ZiGuiApp::Controller::Children;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use DateTime::Tiny;
use feature 'say';
use Encode;
binmode STDOUT, ":encoding(UTF-8)";

# init global MongoDB variables
my $client = MongoDB::MongoClient->new;
$client->dt_type( 'DateTime::Tiny' );
my $db = $client->get_database('BaoBeiHuiJia');
my $lost_children = $db->get_collection('lost_children');
my $homeless_children = $db->get_collection('homeless_children');

sub do_render {
    my $self = shift;
    my $results = shift;
    my $format = $self->param('format') || 'json'; 

    return $self->reply->not_found if $results->count < 1;
    
    my $children = [];
    while (my $doc = $results->next) {
        my $child = {};
        $self->stash(title => $$doc{'姓名'});
        while (my ($key, $value) = each %$doc) {
            next if $key =~ /_id/;
            $child->{$key} = "$value";
        }
        push(@$children, $child);
    }


    if ($format eq 'json') {
        $self->render(json => $children);
    } else {
        # render template children/children.html.ep
        $self->render(template => 'children/children', children => $children);
    }
}

# return 10 children in json format by default
sub all {
    my $self = shift;

    my $skip = $self->param('skip') || 0;    
    my $count = $self->param('count') || 10;   
    my $query = $self->param('query') || '';   
    my $type = $self->stash('type');
    my $cl = ($type =~ /lost/i) ? $lost_children : $homeless_children;

    my $results = $cl->find({})->sort({'注册时间'=>-1})->limit($count)->skip($skip);
    $self->do_render($results);
}

sub single_child {
    my $self = shift;
    my $id = $self->stash('id') || '';   
    my $type = $self->stash('type');
    my $cl = ($type =~ /lost/i) ? $lost_children : $homeless_children;

    my $results = $cl->find({'寻亲编号' => int($id)});
    $self->do_render($results);
}

1;
