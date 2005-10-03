# $Id: Makefile.PL,v 1.8 2005/09/19 12:07:58 mike Exp $

use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Alvis::Pipeline',
    VERSION_FROM      => 'lib/Alvis/Pipeline.pm', # finds $VERSION
    PREREQ_PM         => {
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Alvis/Pipeline.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Taylor <mike@indexdata.com>') : ()),
    EXE_FILES    => [ 'bin/alvis-pipeline-put.pl',
		      'bin/alvis-pipeline-filter.pl',
		      'bin/alvis-pipeline-get.pl' ],
);
