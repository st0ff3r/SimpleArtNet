package LedController;

use File::Temp qw( tempfile tempdir );
use File::Copy;
use Image::Magick;
use Image::Size;
use Config::Simple;
use File::Path qw(remove_tree);
use Proc::Killall;
use IPC::ShareLite;
use Data::Dumper;

use constant ARTNET_CONF => '/led_controller/artnet.conf';
use constant SLITSCAN_IMAGE_MAX_HEIGHT => 10000;

my $config = new Config::Simple(ARTNET_CONF);

sub new {
	my $class = shift;
	my %p = @_;
	my $self = {};

	$self->{slitscan_image} = new Image::Magick;
	$self->{processing_progress} = IPC::ShareLite->new(
		-key		=> 6455,
		-create		=> 'yes',
		-destroy	=> 'no'
	) or die $!;
	
	$self->{processing_progress}->store(0.0);
	
	bless $self, $class;

	return($self);
}

sub movie_to_artnet {
	my $self = shift;
	my %p = @_;
	
	my $movie_file = $p{movie_file};
	my $artnet_data_file = $p{artnet_data_file};
	my $loop_forth_and_back = $p{loop_forth_and_back} || undef;

	# movie file was uploaded
	$self->{processing_progress}->store(50.0);

#	warn "ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $movie_file 2>&1";
	my $fps = `ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $movie_file 2>&1`;
	$fps = eval($fps);
	
	my $temp_dir = tempdir( CLEANUP => 0 );
	my $movie_duration;
	my $movie_converted;
	my $movie_convertion_progress;

	# convert movie to images
#	warn(	"ffmpeg -i " . $movie_file . 
#				qq[ -vf "scale=] . $config->param('num_pixels') . qq[:-2:flags=neighbor,crop=] . $config->param('num_pixels') . qq[:1:0:" ] .
#				"-r " . $fps . " " . 
#				$temp_dir . "/%08d.png");
	open(FFMPEG, "ffmpeg -i " . $movie_file . 
				qq[ -progress - -vf "scale=] . $config->param('num_pixels') . qq[:-2:flags=neighbor,crop=] . $config->param('num_pixels') . qq[:1:0:" ] .
				"-r " . $fps . " " . 
				$temp_dir . "/%08d.png 2>&1 |");
	# read and parse output from ffmpeg and update progress stats
	while (<FFMPEG>) {
		if (/Duration: (\d{2}):(\d{2}):(\d{2})(\.\d+),/) {
			$movie_duration = $1 * 60 * 60 + $2 * 60 + $3 + $4;
		}
		if (/out_time=(\d{2}):(\d{2}):(\d{2})(\.\d+)/) {
			$movie_converted = $1 * 60 * 60 + $2 * 60 + $3 + $4;
			$movie_convertion_progress = $movie_converted / $movie_duration;
			$self->{processing_progress}->store(50 + ($movie_convertion_progress * 25));
#			warn "ffmpeg progress: $movie_convertion_progress\n";
		}
	}
	
	# get all images
	opendir(DIR, $temp_dir) || die "can't opendir $temp_dir: $!";
	my @images = grep { -f "$temp_dir/$_" } readdir(DIR);
	closedir DIR;

	# prepare slitscan image
	my $slitscan_image_height = scalar(@images);
	if ($slitscan_image_height > SLITSCAN_IMAGE_MAX_HEIGHT) {	# crop image height to SLITSCAN_IMAGE_MAX_HEIGHT
		$slitscan_image_height = SLITSCAN_IMAGE_MAX_HEIGHT;
	}
	$self->{slitscan_image}->Set(size=>$config->param('num_pixels') . 'x' . $slitscan_image_height);
	$self->{slitscan_image}->ReadImage('canvas:white');

	my ($image_size_x, $image_size_y);
	my $x;
	my ($fh, $temp_file) = tempfile( CLEANUP => 0 );
	my ($red, $green, $blue);

	print $fh "$fps\n";
	@images = sort { $a cmp $b } @images;
	my $i = 0;
	my $progress_inc = 25.0 / (@images + ($loop_forth_and_back ? @images - 2 : 0));
	foreach (@images) {
		($image_size_x, $image_size_y) = imgsize("$temp_dir/$_");
	
		my $p = new Image::Magick;
		$p->Read("$temp_dir/$_");
		for $x (0..$image_size_x) {
			($red, $green, $blue) = $p->GetPixel( 'x' => $x, 'y' => int($image_size_y / 2) );
			print $fh sprintf("%02x", int($red * 255)) . sprintf("%02x", int($green * 255)) . sprintf("%02x", int($blue * 255));
			if ($i <= $slitscan_image_height) {
				$self->{slitscan_image}->SetPixel(x => $x, y => $i, color=> [$red, $green, $blue]);
			}
		}
		print $fh "\n";
		$i++;
		$self->{processing_progress}->store( $self->{processing_progress}->fetch + $progress_inc);
	}
	if ($loop_forth_and_back && @images >= 3) {
		@images = sort { $b cmp $a } @images;	# sort reversed
		shift(@images);	# remove first image
		pop(@images);	# remove last image
		foreach (@images) {
			($image_size_x, $image_size_y) = imgsize("$temp_dir/$_");
		
			my $p = new Image::Magick;
			$p->Read("$temp_dir/$_");
			for $x (0..$image_size_x) {
				($red, $green, $blue) = $p->GetPixel( 'x' => $x, 'y' => int($image_size_y / 2) );
				print $fh sprintf("%02x", int($red * 255)) . sprintf("%02x", int($green * 255)) . sprintf("%02x", int($blue * 255));
			}
			print $fh "\n";
			$self->{processing_progress}->store( $self->{processing_progress}->fetch + $progress_inc);
		}
	}
	close($fh);
	move($temp_file, $artnet_data_file) || die $!;
	remove_tree($temp_dir);

	# tell send_artnet_data to fade to new
	killall('USR2', 'send_artnet_data');
	
}

sub movie_to_slitscan {
	my $self = shift;
	my %p = @_;

	open(IMAGE, $p{slitscan_file});
	$self->{slitscan_image}->Write($p{slitscan_file});
	close(IMAGE);
}

sub cleanup_temp_files {
	my $self = shift;
	warn "cleaning up temp files\n";
	unlink($temp_file);
	unlink($movie_file);
	remove_tree($temp_dir);
}

1;

__END__
