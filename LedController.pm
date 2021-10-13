package LedController;

use File::Temp qw( tempfile tempdir );
use File::Copy;
use Image::Magick;
use Image::Size;
use Config::Simple;
use Data::Dumper;

use constant ARTNET_CONF => '/led_controller/artnet.conf';

my $config = new Config::Simple(ARTNET_CONF);

sub new {
	my $class = shift;
	my %p = @_;
	my $self = {};

	bless $self, $class;

	return($self);
}

sub movie_to_artnet {
	my $self = shift;
	my %p = @_;
	
	my $movie_file = $p{movie_file};
	my $artnet_data_file = $p{artnet_data_file};
	my $loop_forth_and_back = $p{loop_forth_and_back} || undef;
	
	my $temp_dir = tempdir( CLEANUP => 1 );

	# convert movie to images
	#if (system("ffmpeg -loglevel -8 -i " . $movie_file . " -vf scale=" . $config->param('num_pixels') . ":-1:flags=neighbor " . "-filter:v fps=25 " . $temp_dir . "/%05d.png") != 0) {
	if (system("ffmpeg -loglevel -8 -i " . $movie_file . " -vf scale=" . $config->param('num_pixels') . ":-1:flags=neighbor " . $temp_dir . "/%05d.png") != 0) {
		die "system failed: $?";
	}

	# get all images
	opendir(DIR, $temp_dir) || die "can't opendir $temp_dir: $!";
	my @images = grep { -f "$temp_dir/$_" } readdir(DIR);
	closedir DIR;

	my ($image_size_x, $image_size_y);
	my $x;
	my ($fh, $temp_file) = tempfile( CLEANUP => 0 );
	my ($red, $green, $blue);

	foreach (sort { $a <=> $b } @images) {
		($image_size_x, $image_size_y) = imgsize("$temp_dir/$_");
	
		my $p = new Image::Magick;
		$p->Read("$temp_dir/$_");
		for $x (0..$image_size_x) {
			($red, $green, $blue) = $p->GetPixel( 'x' => $x, 'y' => int($image_size_y / 2) );
			print $fh sprintf("%02x", int($red * 255)) . sprintf("%02x", int($green * 255)) . sprintf("%02x", int($blue * 255));
		}
		print $fh "\n";
	}
	if ($loop_forth_and_back) {
		foreach (sort { $b <=> $a } @images) {
			($image_size_x, $image_size_y) = imgsize("$temp_dir/$_");
		
			my $p = new Image::Magick;
			$p->Read("$temp_dir/$_");
			for $x (0..$image_size_x) {
				($red, $green, $blue) = $p->GetPixel( 'x' => $x, 'y' => int($image_size_y / 2) );
				print $fh sprintf("%02x", int($red * 255)) . sprintf("%02x", int($green * 255)) . sprintf("%02x", int($blue * 255));
			}
			print $fh "\n";
		}
	}
	close($fh);
	move($temp_file, $artnet_data_file) || die $!;	
}

1;

__END__
