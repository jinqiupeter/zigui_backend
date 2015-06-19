package ZiGuiApp;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
 
  # route to /lost_children and /homeless_children
  $r->get('/(:type)_children/')->to('children#all');

  # route to /lost_children/id and /homeless_children/id
  $r->get('/(:type)_children/:id/')->to('children#single_child');

  # route to /images
  $r->get('/images')->to('images#all');

  # route to /images/guid/100x100, /images/guid/small etc
  $r->get('/images/:guid')->to('images#single_image');
  $r->get('/images/:guid/:size' => [size => qr/\d+x\d+/])->to('images#single_image');

  # route to /images/guid/file, /images/guid/file/100x100 etc
  $r->get("/images/:guid/file/")->to('images#single_image_file');
  $r->get("/images/:guid/file/:size" => [size => qr/\d+x\d+/] )->to('images#single_image_file');
}

1;
