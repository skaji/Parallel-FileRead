package Parallel::FileRead;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

sub run {
    (undef, my %arg) = @_;
    my $file      = delete $arg{file};
    my $mode      = delete $arg{mode} || '<';
    my $worker    = delete $arg{worker} || 5;
    my $on_worker = delete $arg{on_worker};

    my $position
        = Parallel::FileRead::Position->new($file, $worker);

    my %worker_pid;
    for my $i ( 0 .. ($worker - 1) ) {
        my $pid = fork;
        die "fork failed" unless defined $pid;
        if ($pid) {
            $worker_pid{$pid}++;
            next;
        }

        my $fh = Parallel::FileRead::FH->new(
            file  => $file,
            mode  => $mode,
            start => $position->start_of($i),
            end   => $position->end_of($i),
        );
        $on_worker->( $fh, $i );
        exit;
    }

    while (%worker_pid) {
        my $pid = wait;
        delete $worker_pid{$pid} if exists $worker_pid{$pid};
    }
}

package Parallel::FileRead::FH;
use Fcntl qw(:seek);
use overload '<>' => 'getline';
sub new {
    my ($class, %option) = @_;
    open my $fh, $option{mode}, $option{file} or die "$option{file}: $!";
    my $start = delete $option{start};
    my $end   = delete $option{end};
    seek $fh, $start, SEEK_SET;
    scalar <$fh> if $start != 0;
    bless { fh => $fh, start => $start, end => $end }, $class;
}
sub getline {
    my ($self) = @_;
    my $fh = $self->{fh};
    return if tell($fh) > $self->{end};
    scalar <$fh>;
}

package Parallel::FileRead::Position;
sub new {
    my ($class, $file, $worker) = @_;
    my $self = bless { file => $file, worker => $worker }, $class;
    $self->BUILD;
    $self;
}

sub BUILD {
    my $self = shift;
    my $size = -s $self->{file};
    my $worker = $self->{worker};
    my $per_size = int( $size / $worker );
    my @position = map { $per_size * $_ } 0 .. ($worker - 1);
    push @position, $size;
    $self->{position} = \@position;
}

sub start_of {
    my ($self, $index) = @_;
    return $self->{position}[$index];
}

sub end_of {
    my ($self, $index) = @_;
    return $self->{position}[$index + 1];
}


1;
__END__

=encoding utf-8

=head1 NAME

Parallel::FileRead - read file in parallel

=head1 SYNOPSIS

  use Parallel::FileRead;

  Parallel::FileRead->run(
      file      => '10GB.log',
      worker    => 5, # how many workers
      on_worker => sub {
          my ($fh, $index) = @_;
          while (my $line = <$fh>) {
              # do something with $line
          }
      },
  );

=head1 DESCRIPTION

Parallell::FileRead helps you read a big file.
Let's say you have to process 10GB file.
Then the above synopsis code splits the process to 5 workers, and
each worker will process 2GB.

=head1 CLASS METHOD

=head2 C<< run(%option) >>

C<< run >> takes the following options:

=over 4

=item C<< file => String >>

File to be processed.

=item C<< mode => String >>

File open mode. Default C<< < >>.

=item C<< worker => Integer >>

How many workers.

=item C<< on_worker => Subroutine Reference >>

The actual job of workers.
The subroutine takes two arguments: filehandle and index of workers.

=back

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@outlook.comE<gt>

=cut

