# $Id: Pipeline.pm,v 1.18 2005/10/24 14:26:40 mike Exp $

package Alvis::Pipeline;

use 5.008;
use strict;
use warnings;

use Alvis::Logger;
use Alvis::Pipeline::Read;
use Alvis::Pipeline::Write;

our $VERSION = '0.06';


=head1 NAME

Alvis::Pipeline - Perl extension for passing XML documents along the Alvis pipeline

=head1 SYNOPSIS

 use Alvis::Pipeline;
 $in = new Alvis::Pipeline::Read(host => "harvester.alvis.info",
                                 port => 16716,
                                 spooldir => "/home/alvis/spool");
 $out = new Alvis::Pipeline::Write(port => 29168);
 while ($xmlDOM = $in->read(1)) {
     $transformed = process($xmlDOM);
     $out->write($transformed);
 }

=head1 DESCRIPTION

This module provides a simple means for components in the Alvis
pipeline to pass documents between themselves without needing to know
about the underlying transfer protocol.  Pipe objects may be created
either for reading or writing; components in the middle of the
pipeline will create one of each.  Pipes support exactly one method,
which is either C<read()> or C<write()> depending on the type of the
pipe.  The granularity of reading and writing is
the XML document; neither smaller fragments nor larger aggregates can
be transferred.

The documents expected to pass through this pipeline are those
representing documents acquired for, and being analysed by, Alvis.
These documents are expressed as XML contructed according to the
specifications described in the Metadata Format for Enriched
Documents.  However, while this is the motivating example pipeline
that led to the creation of this module, there is no reason why other
kinds of documents should not also be passed through pipeline using
this software.

=head1 METHODS

=head2 new()

 $in = new Alvis::Pipeline::Read(host => "harvester.alvis.info",
                                 port => 16716,
                                 spooldir => "/home/alvis/spool");
 $out = new Alvis::Pipeline::Write(port => 29168);

Creates a new pipeline, either for reading or for writing.  Any number
of I<name>-I<value> pairs may be passed as parameters.  Among these,
most are optional but some are mandatory:

=over 4

=item *

Read-pipes must specify both the C<host> and C<port> of the component
that they will read from, and C<spooldir>,
a directory that is writable to the user the process is running as.
(When files become available by being written down a write-pipe, they
are immediately read in the background, then stored in the
specified spool directory until picked up by a reader.)

=item *

Pipes may specify C<loglevel> [default 0]: higher levels
providing some commentary on under-the-hood behaviour.

=back

=head2 option()

 $old = $pipe->option("foo");
 $pipe->option(bar => 23);

Can be used to set the value for a specific option, or to retrieve its
value.

=head2 read()

 # Read-pipes only
 $xmlDOM = $in->read($block);

Reads an XML document from the specified inbound pipe, and returns a
DOM tree representing it.  If there is no document ready to read, it
either returns an undefined value (if no argment is provided, or if
the argument is false) or blocks if the argument is provided and true.
C<read()> throws an exception if an error occurs.

Once a document has been read in this way, it will no longer be
available for subsequent C<read()>s, so a sequence of C<read()> calls
will read all the available records one at a time.

=head2 write()

 # Write-pipes only
 $out->write($xmlDocument);

Writes an XML document to the specified outbound pipe.  The document
may be passed in either as a DOM tree (C<XML::LibXML::Element>) or a
string containing the text of the document.  Throws an exception if an
error occurs.

=head2 close()

 $pipe->close();

Closes a pipe, after which no further reading or writing may be done
on it.  This is important for read-pipes, as it frees up the Internet
port that the server is listening on.

=head1 SEE ALSO

I<Alvis Task T3.2 - Metadata Format for Enriched Documents.
Milestone M3.2 - Month 12 (December 2004).>
Includes a useful overview of the Alvis processing pipeline.
http://www.miketaylor.org.uk/alvis/t3-2/m3-2.html

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


# Instantiation setup code shared by both subclasses
sub _setopts {
    my $this = shift();
    my(%opts) = @_;

    my $loglevel = delete $opts{loglevel};
    $this->{logger} = new Alvis::Logger(level => $loglevel);
    $this->{opts} = \%opts;
}


sub option {
   my $this = shift();
   my($key, $newval) = @_;

   my $val = $this->{opts}->{$key};
   $this->{opts}->{$key} = $newval if defined $newval;
   return $val;
}


sub log {
    my $this = shift();
    my $level = shift();
    $this->{logger}->log($level, $$, ": ", @_);
}


1;
