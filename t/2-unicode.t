# $Id: 2-unicode.t,v 1.2 2006/07/11 10:38:01 mike Exp $

use strict;
use warnings;

use vars qw(@docs $ndocs);
BEGIN {
    @docs = (
	     # I think all of the first three fit in eight-bit bytes
	     "simple US-ASCII document",
	     "This one contains £ a pound sign",
	     "Danish character Søren",
	     # Now include the Unicode smiley-face character
	     "Hello \x{263A} world!",
	     "Goodbye \x{263B} world!",
	     "Happy \x{263A}\x{263B}\x{263A}\x{263B} sad",
    );
    $ndocs = @docs;
}
use Test::More tests => 3+$ndocs;

BEGIN { use_ok('Alvis::Pipeline') }

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
				     loglevel => 0, sleep => 1)
    or die "can't make read-pipe with spooldir='$spooldir', port='$port': $!";

# It's very, very stupid that we have to do this.
binmode Test::Builder::new()->output(), ":utf8";

for my $i (1..$ndocs) {
    my $doc = $pipe->read(1);
    my $nb;
    { use bytes; $nb = length($doc) }
    my $nc = length($doc);
    ok($doc eq $docs[$i-1],
       "read document $i of $ndocs ($nb bytes, $nc chars) '$doc'");
}

my $doc = $pipe->read();	# non-blocking
ok(!defined $doc, "document " . ($ndocs+1) . " not available");
$pipe->close();

system("rm -r $spooldir");


sub generate_and_send {
    sleep(1);			# Allow time for read-pipe to start up

    my $pipe = new Alvis::Pipeline::Write(host => "localhost",
					  port => $port)
	or die "can't make write-pipe to localhost with port='$port': $!";
    for my $i (1..$ndocs) {
	my $doc = $docs[$i-1];
	my $nb;
	{ use bytes; $nb = length($doc) }
	my $nc = length($doc);
	$pipe->write($doc);
    }
    $pipe->close();
}