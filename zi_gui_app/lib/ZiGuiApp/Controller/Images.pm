package ZiGuiApp::Controller::Images;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use DateTime::Tiny;
use feature 'say';
use Encode;
use MIME::Base64;
use File::Basename;
use Mojo::Home;
use Image::Magick;
binmode STDOUT, ":encoding(UTF-8)";

# init global MongoDB variables
my $client = MongoDB::MongoClient->new;
$client->dt_type( 'DateTime::Tiny' );
my $db = $client->get_database('BaoBeiHuiJia');
my $images = $db->get_collection('images');

sub resize {
    my ($self, $image_data, $size) = @_;
    return $image_data if $size =~ /^$/ || $size !~ /^\d+x\d+$/;

    my $image = Image::Magick->new(magick=>'jpg');
    my $decoded_data = decode_base64($image_data);
    $image->BlobToImage($decoded_data);
    $image->Resize(geometry => $size);
    my $blob = $image->ImageToBlob();
    undef $image;

    return encode_base64($blob);
}

sub do_render {
    my $self = shift;
    my $results = shift;
    my $size = shift || '';
    my $format = $self->param('format') || 'json'; 

    return $self->reply->not_found if $results->count < 1;
    my $images = [];
    while (my $doc = $results->next) {
        my $image = {};
        while (my ($key, $value) = each %$doc) {
            $value = $self->resize($value, $size) if $key =~ /data/;
            $image->{$key} = "$value";
        }
        push(@$images, $image);
    }

    if ($format eq 'json') {
        $self->render(json => $images);
    } else {
        my $paths = [];
        my $home = Mojo::Home->new;
        my $app_dir = $home->detect('ZiGuiApp');
        foreach my $image (@$images) {
            my $name = "$app_dir/public/$$image{guid}$size";
            my $path = "$name.jpg";
            push (@$paths, basename($name));
            next if (-e $path);
            my $decoded_data = decode_base64($$image{data});
            open FILE, ">$path" or die "can not open $path: $!";
            print FILE $decoded_data;
            close FILE;
        }

        $self->render(template => 'images/images', image_paths => $paths);
    }
}

# return 10 children in json format by default
sub all {
    my $self = shift;

    my $skip = $self->param('skip') || 0;    
    my $count = $self->param('count') || 10;   

    my $results = $images->find({})->limit($count)->skip($skip);
    $self->do_render($results);
}

sub single_image {
    my $self = shift;
    my $guid = $self->stash('guid') || '';   
    my $size = $self->stash('size') || '';

    my $results = $images->find({'guid' => $guid});
    $self->do_render($results, $size);
}

sub single_image_file {
    my $self = shift;
    my $guid = $self->stash('guid') || '';   
    my $size = $self->stash('size') || '';

    # look for files in $APP_DIR/public by default
    $self->reply->static("$guid$size.jpg");
}

1;
