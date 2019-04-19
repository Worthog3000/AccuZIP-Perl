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
use Config::Std;
use Perl6::Say;
use Carp;
use Data::Dumper;
use Term::ProgressBar;

$|++;

my $sleep   = 30;

my $config_file	= 'mail.cfg';
my $cass_only++;	# Default
my $cass_ncoa_only;
my $cass_ncoa_presort; 
my $cass_presort;
my $eddm;

GetOptions( "config|cfg|c=s"		=> \$config_file,
	    "C|CASS-only!"		=> \$cass_only,
	    "CN|CASS-NCOA-only!"	=> \$cass_ncoa_only,
	    "CP|CASS-PRESORT!"		=> \$cass_presort,
	    "CNP|CASS-NCOA-PRESORT!"	=> \$cass_ncoa_presort,
	    "eddm|E!"			=> \$eddm,
    );

my $infile  = $ARGV[0];

# Check for proper extension
croak "Upload file must end in *.csv"
    unless $infile =~ m/\.csv$/;

$eddm++ if $infile eq 'eddm@.csv';

if ( $eddm && $infile ne 'eddm@.csv' ) {
    croak "Upload file must be \"eddm@.csv\" for EDDM jobs!";
}

# CHECK FOR PRESORT CONFIG FILE
if ( ( $cass_presort || $cass_ncoa_presort ) && not -e $config_file ) {
    say "No config file named $config_file or specified on the command line with the --config switch. ";
    exit;
}

#  1.	Upload the data file, get GUID
#	TODO: Validate the field names and contents. For now, we'll
#	do all of that outside of this script.
#	Required fields:    First	may contain FIRST or FULL_NAME
#			    Address	primary address, ADDRESS1
#			    City	may contain CITY or CITYSTZIP
#	Optional fields:    Middle
#			    Last
#			    Address2
#			    St
#			    Zip
#			    Company

say STDERR "Uploading $infile";
my $guid    = accuzip_upload( $infile );
croak "Something went wrong!"
    unless $guid;
say STDERR "GUID returned: $guid";
open my $fh, '>', $guid
    or die "Can't open a file named $guid: $!";
print $fh $guid;
close $fh;

# Stop here if we are uploading an EDDM file
if ( $eddm ) {
    exit;
}

say STDERR "Initiating CASS";
accuzip_cass( $guid )
    or croak "CASS failed: $!";
sleep 10;

if ( $cass_ncoa_only || $cass_ncoa_presort ) {
    say STDERR "Initiating NCOA";
    accuzip_ncoa( $guid )
	or croak "NCOA failed: $!";
    sleep 10;
}


if ( $cass_presort || $cass_ncoa_presort ) {
    read_config $config_file => my %CONFIG;
    # TODO: Validate %CONFIG

    # We have to alter the two-level hash slurped in from the
    # config file into a "flat" hash
    # Maybe change how we handle the config file to avoid this?
    my %MAIL = ();
    foreach ( keys %CONFIG ) {
	while ( my ( $k, $v ) = each %{ $CONFIG{ $_ } } ) {
	    $MAIL{ $k }	= $v;
	}
    }
    #print Dumper \%MAIL;
    #print Dumper $CONFIG{ Piece };
    say STDERR "Posting mail stats";
    accuzip_mailcfg( $guid, \%MAIL ) 
	or croak "Mail config failed: $!";
    sleep 10;

    say STDERR "Initiating Presort";
    my $result = accuzip_presort( $guid );
    say STDERR $result;

}

#print STDERR accuzip_status( $gid );

say $guid;
