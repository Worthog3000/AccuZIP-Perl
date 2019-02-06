#!/usr/bin/perl
#
# Purpose:  1. Upload File
#	    2. CASS, NCOA and/or Presort
# Usage: 

use strict;
use warnings;
use EGA::Utils;
use EGA::AccuZIP;
use List::Util;
use Getopt::Long;
use Perl6::Say;
use Carp;

$|++;

my $debug;

GetOptions( "preview|debug!"	=> \$debug,
);

my $guid    = $ARGV[0];
my ( $qty, $price ) = $debug
		    ? accuzip_fetch_preview( $guid )
		    : accuzip_fetch_csv( $guid )
		    ;
printf "Qty:  %7d\nPrice: \$%2.2f\n", $qty, $price;
