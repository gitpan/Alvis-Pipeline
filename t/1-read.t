# $Id: 1-read.t,v 1.5 2005/10/03 13:14:33 mike Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1-read.t'

#########################

use strict;
use warnings;
use Errno qw(EINVAL ENOENT);

# change 'tests => 1' to 'tests => last_test_to_print';
use vars qw($ndocs);
BEGIN { $ndocs = 10 } # must be an even number
use Test::More tests => 3+$ndocs;

BEGIN { use_ok('Alvis::Pipeline') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $spooldir = "/tmp/xyzzy";
my $port = 31802;

my $pid = fork();
die "can't fork: $!" if $pid < 0;
if ($pid == 0) {
    # Child: generate documents and send them.
    generate_and_send();
    exit;
}

ok(1, "reading parent $$ spawned writing child with pid=$pid");

# Parent: read documents generated by child
my $pipe = new Alvis::Pipeline::Read(spooldir => $spooldir, port => $port,
				     loglevel => 0)
    or die "can't make read-pipe with spooldir='$spooldir', port='$port': $!";

for my $i (1..$ndocs) {
    my $doc = $pipe->read(1);
    ok($doc == $i*$i, "read document $i of $ndocs, got square '$doc'");
}

my $doc = $pipe->read();	# non-blocking
ok(!defined $doc, "document " . ($ndocs+1) . " not available");
$pipe->close();

system("rm -r $spooldir");


sub generate_and_send {
    sleep(1);			# Allow time for read-pipe to start up

    my $i = 1;
    for (1..2) {
	my $pipe = new Alvis::Pipeline::Write(host => "localhost",
					      port => $port)
	    or die "can't make write-pipe to localhost with port='$port': $!";

	for (1..$ndocs/2) {
	    my $doc = $i*$i;
	    $pipe->write($doc);
	    $i++;
	}

	$pipe->close();
	# Leave gap between first and second writing clients.
	sleep(11) if $i < $ndocs;
    }
}
