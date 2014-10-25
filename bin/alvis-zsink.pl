#!/usr/bin/perl -w

# $Id: alvis-zsink.pl,v 1.1 2006/07/11 10:36:49 mike Exp $
#
# This is an Alvis Sink -- that is, a program that sits at the end of
# an Alvis pipeline absorbing documents that are fed to it from an
# Alvis Source, most likely through a series of one or more filters
# that add semantic annotation.  It deals with the records by feeding
# them to an Extended-Services-compliant Z39.50 server, most likely
# Zebra.
#
# The program needs to be told what port to listen on (for the
# pipeline) and what host/port to write to (for the Z39.50 server).
# For example, to listen on port 8021 and feed documents to a server
# on localhost:9996, use:
#	alvis-zsink.pl 8021 localhost:9996

use strict;
use warnings;
use Alvis::Pipeline 0.07;
use ZOOM;

if (@ARGV != 2 && @ARGV != 4) {
    print STDERR <<__EOT__;
Usage: $0 <listen-port> <z-host> [<user> <password>]
    <listen-port> is the port on which to listen for documents being
    fed down the Alvis pipeline; <z-host> is ZOOM-style Z39.50 host
    string such as 'localhost:9996' or 'tcp:alvis.indexdata.com:8122'
__EOT__
    exit 1;
}

my($port, $zhost, $user, $password) = @ARGV;
my $pipe = new Alvis::Pipeline::Read(port => $port,
				     spooldir => "/tmp/alvis-spool")
    or die "can't create read-pipe on port $port: $!";
$pipe->option(sleep => 1);

my $options = new ZOOM::Options();
$options->option(user => $user) if defined $user;
$options->option(password => $password) if defined $password;
my $conn = create ZOOM::Connection($options);
$conn->connect($zhost);

my $n = 0;
$| = 1;
while (my $xml = $pipe->read(1)) {
    print "got document ", ++$n, " ... ";
    my $p = $conn->package();
    $p->option(action => "specialUpdate");
    $p->option(record => $xml);
    # Could set "recordIdOpaque" if we had a record-ID
    $p->send("update");
    print "sent package ... ";
    $p->destroy();

    sleep 1;
    $p = $conn->package();
    $p->option(action => "commit");
    $p->send("commit");
    print "commit ... ";

    print STDERR "added document\n";
}
