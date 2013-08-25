# NAME

Parallel::FileRead - read file in parallel

# SYNOPSIS

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

# DESCRIPTION

Parallell::FileRead helps you read a big file.
Let's say you have to process 10GB file.
Then the above synopsis code splits the process to 5 workers, and
each worker will process 2GB.

# CLASS METHOD

## `run(%option)`

`run` takes the following options:

- `file => String`

    File to be processed.

- `mode => String`

    File open mode. Default `<`.

- `worker => Integer`

    How many workers.

- `on_worker => Subroutine Reference`

    The actual job of workers.
    The subroutine takes two arguments: filehandle and index of workers.

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@outlook.com>
