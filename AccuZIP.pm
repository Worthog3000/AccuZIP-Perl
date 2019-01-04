package EGA::AccuZIP;
require Exporter;

our @ISA	= qw( Exporter );
our @EXPORT	= qw(
			accuzip_upload
			accuzip_status
			accuzip_cass
			accuzip_ncoa
			accuzip_mail
			accuzip_cass_presort
			accuzip_cass_ncoa_presort
		    );

use strict;
use Carp;
use LWP::UserAgent;
use JSON::XS;
use Perl6::Slurp;
use Data::Dumper;

our $VERSION	= 1.00;

# AccuZIP API
my $api_key = '7CD54237-2D50-4D05-8E6A-0D5DC89CFAE7';
my %URLS    = (
    upload	=> 'https://cloud2.iaccutrace.com/ws_360_webapps/v2_0/uploadProcess.jsp?manual_submit=false',
    process 	=> 'https://cloud2.iaccutrace.com/servoy-service/rest_ws/ws_360/v2_0/job',
    callback	=> 'http://cirrus.ega.com/getAccuZIPcallback',
    );

# DEFAULTS
my @mailing_agent   = ( 
    'Mike Edwards', 
    'Edwards Graphic Arts', 
    '2700 Bell Ave', 
    'Des Moines, IA 50321' 
    );
my $mailing_agent_phone	= '5156976503';

my %DEFAULT = (
    mailing_agent_phone			=> $mailing_agent_phone,
    agent_or_mailer_signing_statement	=> $mailing_agent[0],
    agent_or_mailer_company          	=> $mailing_agent[1],
    agent_or_mailer_phone          	=> $mailing_agent_phone,

    mailing_agent_name_address		=> ( join '|', @mailing_agent ),
    mailing_agent_crid			=> 2475894,
    mailing_agent_edoc_sender_crid	=> 2475894,
    mailing_agent_mailer_id		=> 905376001,	# Unless PARCELS!

    drop_zip				=> '50303',
    calculate_container_volume		=> 1,
    machinability			=> 'MACHINABLE',
    print_barcode			=> 1,
    print_imb				=> 1,
    weight_unit				=> 'OUNCES',
    include_crrt			=> 1,
    statement_number			=> 1,
    );


1;

sub accuzip_cass {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'CASS';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ success } || 0;
}

sub accuzip_ncoa {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'NCOA';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ success } || 0;
}

sub accuzip_cass_ncoa_presort {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'CASS-NCOA-PRESORT';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ success } || 0;
}

sub accuzip_cass_presort {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'CASS-PRESORT';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ success } || 0;
}

sub accuzip_status {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'QUOTE';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ task_name } || 0;
}

sub accuzip_mail {
    my $guid	= shift;
    my $MAIL	= shift;    # This should be a hashref

#    my $tray_type	= $CONFIG{ Piece }{ mail_piece_size } =~ m/FLAT/i
#			? '0MM'
#			: 'EMM'
#			;
#    my $include_non_zip4    = $CONFIG{ Mailing }{ presort_class } =~ m/FC/i
#			? 1
#			: 0
#			;
#    my $pallets         	= $CONFIG{ Mailing }{ presort_class } =~ m/FC/i
#			? 0
#			: 1
#			;
#    my $packages_on_pallets	= $CONFIG{ Piece }{ mail_piece_size } =~ m/(FLAT|PARCEL)/i
#			? 1
#			: 0
#			;

    
    my $url	= join '/', $URLS{ process }, $guid, 'QUOTE';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->put( 
		    $url,
		    Content_Type    => 'application/json',
		    Content	    => encode_json( $MAIL ),
		);
    carp "Error posting mailing details at $url: " . $resp->status_line
	unless $resp->is_success;
    if ( $resp->status_line =~ m/200/ ) {
	return 1;
    }
    else {
	return 0;
    }
}

sub accuzip_upload {
    # Returns the guid on success or 0 on failure
    my $FILE	= shift;
    my %DATA    = (
		'backOfficeOption'  => 'json',
		'apiKey'	    => $api_key,
		'callbackURL'	    => $URLS{ callback },
		'guid'		    => '',
		'file'		    => [ $FILE ],
		);
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    my $resp    = $ua->post(
		    $URLS{ upload }, 
		    Content_Type    => 'multipart/form-data', 
		    Content	    => \%DATA,
		    Cache_Control   => 'no-cache',
		);
    carp "Error posting to $URLS{ upload }: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ guid } || 0;
}


