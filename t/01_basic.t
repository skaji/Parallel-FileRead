use strict;
use warnings;
use utf8;
use Test::More;
use Parallel::FileRead;
use File::Temp ();
sub tempfile {
    (undef, my $file) = File::Temp::tempfile(UNLINK => 1);
    $file;
}
sub spew {
    my ($msg, $file) = @_;
    open my $fh, ">", $file or die;
    print {$fh} $msg;
    close $fh;
}
sub slurp {
    my ($file) = @_;
    open my $fh, "<", $file or die;
    local $/; <$fh>;
}

my $bigfile = tempfile;
spew join("\n", 1..10000) => $bigfile;

my $worker = 5;
my @tempfile = map { tempfile } 0..($worker -1);

Parallel::FileRead->run(
    file   => $bigfile,
    worker => $worker,
    on_worker => sub {
        my ($fh, $index) = @_;
        my ($min, $max);
        my $first = 1;
        while (my $line = <$fh>) {
            chomp $line;
            if ($first) {
                $min = $line;
                $first = 0;
            }
            $max = $line;
        }
        spew "$$,$min,$max" => $tempfile[$index];
    },
);

my $previous_max = 0;
for my $i (0..($worker -1)) {
    my ($pid, $min, $max) = split /,/, slurp($tempfile[$i]);
    is $min, $previous_max + 1;
    $previous_max = $max;
    diag join ", ", $pid, $min, $max;
}


done_testing;

