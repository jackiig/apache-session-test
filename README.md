# Apache Session Test

This project is intended as a test bed to try to identify bugs within
[Apache::Session::MySQL](http://search.cpan.org/~chorny/Apache-Session-1.93/lib/Apache/Session/MySQL.pm).

## Install

It is easiest to [install Docker](https://docs.docker.com/mac/started/),
and get running from there.

## Create the database table required.

In order to create the database, start by bringing up the server.  This may take
some time the first run through, and it is expected that the `web` container
will fail until the database exists.

    $ docker-compose up

> If you are on a Mac or windows machine, you may need to use `docker-machine`
> to assertain the IP address of your docker host.  The machine is usually
> called `default`, so you can use the command `docker-machine ip default`.
> For this example, I will use `192.168.99.100`, which was the default on my
> Mac.

Connect to the MySQL database using the default root password (this is for
experimentation only, so it's `abc123`).  Yes, the port is `3307`, not `3306`,
that's not a typo.  You can change this in `docker-compose.yml` if you'd like.

    $ mysql -u root -pabc123 -h 192.168.99.100 -p 3307 polmaker

Add the `sessions` table using the following:

    CREATE TABLE sessions (
    	`id` varchar(32) NOT NULL,
    	`a_session` longtext,
    	PRIMARY KEY  (`id`)
    ) DEFAULT CHARSET=latin1;

Now you can restart `docker-compose` and the system should be up and running
on [http://192.168.99.100:8000/](http://192.168.99.100:8000/).

# Enable Debugging

In the `handler.pl` file is a commented out line with a `use lib` pointing to
the apps directory within Docker.  This will Enable loading of two files within this project:

  - `lib/Apache/Session/MySQL.pm` - Changes from the default MD5 session ID
  generator to a UUID generator.
  - `lib/Apache/Session/Lock/MySQL.pm` - Adds `warn Dumper()` statements around
  the key points in generating and using a lock file.

I have also commented out the code for using `Apache::Session::File` instead of
`Apache::Session::MySQL`.  Simply change the session logic to swap the comments
and you should stop seeing errors from the benchmark.

	session_class        		=>	'Apache::Session::File',
	session_directory => '/tmp',
	session_lock_directory => '/tmp',
	session_lock				=>	'File',
	# session_class        		=>	'Apache::Session::MySQL',
	# session_lock				=>	'MySQL',
	# session_handle				=>	$DBH,
	# session_lock_handle			=>	$DBH,

**Be sure to reboot the web component each time you make a change to the
`handler.pl` file.**

# Load-test the newly running system.

Found a great, small, Go app called
[Gobench](https://github.com/cmpxchg16/gobench) to benchmark the system.  I
also took the liberty of packaging this up into a [Docker container](https://hub.docker.com/r/jackiig/gobench/).
This has an advantage over Apache Benchmark that it reports the number of
pages which failed due to network timeout or non-200 HTTP responses.  Again,
you may need to substitute the IP in the following command.

    $ docker run jackiig/gobench gobench -c=2 -r=2 -k=false -u=http://192.168.99.100:8000/

To break this command down a bit:

- `-c=2` - Concurrency level.  This example will use two concurrent workers.
- `-r=2` - Requests per concurrent worker.  As a result, this example will
create 4 total requests to the server.
- `-k=false` - Disabled HTTP Keep-Alive.
- `-u=<url>` - URL to test.  Pretty strait forward.

# Conclusions

In my testing, I found that with as few as two concurrent users, the application
often hung on at least one of the requests.  Increasing the concurrency seemed
to worsen the problem.
