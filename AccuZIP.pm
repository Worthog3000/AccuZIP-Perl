package EGA::AccuZIP;
require Exporter;

our @ISA	= qw( Exporter );
our @EXPORT	= qw(
			accuzip_upload
			accuzip_status
			accuzip_process_complete
			accuzip_eddm_status
			accuzip_cass
			accuzip_ncoa
			accuzip_mailcfg
			accuzip_presort
			accuzip_cass_presort
			accuzip_cass_ncoa_presort
			accuzip_fetch_preview
			accuzip_fetch_csv
			accuzip_price
			accuzip_dup_indiv
			accuzip_dup_household
			accuzip_dup_addronly

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
    download	=> 'https://cloud2.iaccutrace.com/ws_360_webapps/download.jsp?guid=#GUID#&ftype=#TYPE#',
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
my $mailing_agent_email	= 'mike.edwards+accuzip@ega.com';

my %PRESORT_DEFAULTS = (
    mailing_agent_phone			=> $mailing_agent_phone,
    agent_or_mailer_signing_statement	=> $mailing_agent[0],
    agent_or_mailer_company          	=> $mailing_agent[1],
    agent_or_mailer_phone          	=> $mailing_agent_phone,
    agent_or_mailer_email          	=> $mailing_agent_email,

    mailing_agent_name_address		=> ( join '|', @mailing_agent ),
    mailing_agent_crid			=> '2475894',
    mailing_agent_edoc_sender_crid	=> '2475894',
    mailing_agent_mailer_id		=> '905376001',	# Unless PARCELS!

    drop_zip				=> '50303',
    calculate_container_volume		=> '1',
    machinability			=> 'MACHINABLE',
    print_barcode			=> '1',
    print_imb				=> '1',
    weight_unit				=> 'OUNCES',
    include_crrt			=> '1',
    statement_number			=> '1',

    col_first				=> 'FIRST',
    col_address				=> 'ADDRESS',
    col_city				=> 'CITY',
    );

my @PRICING = (
    [      1,     199,  1 ],
    [    200,    1000,  4 ],
    [   1001,    2000,  6 ],
    [   2001,    5000,  8 ],
    [   5001,   10000, 11 ],
    [  10001,   20000, 16 ],
    [  20001,   50000, 27 ],
    [  50001,  100000, 48 ],
    [ 100001, 1000000, 48 ],
);

1;

sub accuzip_price {
    # The pricing model is completely based on the 
    # nunmber of records downloaded, reagrdless of
    # the service(s) requested.
    my $qty	= shift;
    my $price	= '0.00';

    if ( $qty > @{ $PRICING[-1] }[1] ) {
	carp "$qty exceeds the maximum available.";
	return $price;
    }

    foreach my $tier ( @PRICING ) {
	if ( $qty >= @{ $tier }[0] && $qty <= @{ $tier }[1] ) {
	    $price  = sprintf "%2.2f", @{ $tier }[2];
	}
    }
    return $price;
}

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

sub accuzip_dup_indiv {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'DUPS', '02';
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

sub accuzip_dup_household {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'DUPS', '03';
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

sub accuzip_dup_addronly {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'DUPS', '01';
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
    $ua->show_progress( 1 );
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    return $CONTENT->{ success } || 0;
}

sub accuzip_presort {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'PRESORT';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    print Dumper $CONTENT;
    return $CONTENT->{ success } || 0;
}

sub accuzip_cass_ncoa_presort {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'CASS-NCOA-PRESORT';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    print Dumper $CONTENT;
    return $CONTENT->{ success } || 0;
}

sub accuzip_cass_presort {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'CASS-PRESORT';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );
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
    #$ua->show_progress( 1 );
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    #print Dumper $CONTENT;
    my $count	= $CONTENT->{ total_records };
    my $task	= $CONTENT->{ task_name } || 'NO TASK RETURNED';
    return "$count records; Task: $task";
}

sub accuzip_process_complete {
    my $guid	= shift;
    if ( accuzip_status( $guid ) =~ m/FINISHED/ ) {
	return 1;
    }
    else {
	return 0;
    }
}

sub accuzip_eddm_status {
    my $guid	= shift;
    my $url	= join '/', $URLS{ process }, $guid, 'QUOTE';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );
    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $CONTENT = decode_json( $resp->content );
    #print Dumper $CONTENT;
    my $count1	= $CONTENT->{ Total_Residential };
    my $count2	= $CONTENT->{ Total_Possible };
    return "$count1 Residential records; $count2 Possible records";
}

sub accuzip_mailcfg {
    my $guid	= shift;
    my $CFG	= shift;    # This should be a hashref

    # Passed values will override defaults

    # Generate some values based on others
    $CFG->{ tray_type }		    = $CFG->{ mail_piece_size } =~ m/FLAT/i
				    ? '0MM'
				    : 'EMM'
				    ;
    $CFG->{ include_non_zip4 }	    = $CFG->{ presort_class } =~ m/FIRST CLASS/i
				    ? '1'
				    : '0'
				    ;
    $CFG->{ pallets }		    = $CFG->{ presort_class } =~ m/FIRST CLASS/i
				    ? '0'
				    : '1'
				    ;
    $CFG->{ packages_on_pallets }   = $CFG->{ mail_piece_size } =~ m/(FLAT|PARCEL)/i
				    ? '1'
				    : '0'
				    ;

    my %MAIL	= ();
    foreach my $ref ( \%PRESORT_DEFAULTS, $CFG ) {
	while ( my ( $k, $v ) = each %{ $ref } ) {
	    $MAIL{ $k } = $v;
	}
    }
    my $json	= JSON::XS->new->pretty(1)->encode( \%MAIL );
    #my $json = encode_json( \%MAIL );
    print $json;
    #print Dumper \%MAIL;
    
    my $url	= join '/', $URLS{ process }, $guid, 'QUOTE';
    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );
    my $resp    = $ua->put( 
		    $url,
		    Content_Type    => 'application/json',
		    Content	    => encode_json( \%MAIL ),
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
    $ua->show_progress( 1 );
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

sub accuzip_fetch_preview {
    my $guid	= shift;
    print STDERR "WARNING: Downloading a preview file will only work if the job has been presorted.";
    
    my $type	= 'prev.csv';
    my $local	= 'preview.csv';

    my $url	= $URLS{ download };
    $url	=~ s{#GUID#}{$guid};
    $url	=~ s{#TYPE#}{$type};

    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );

    my $resp    = $ua->get( $url );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    my $file	= $resp->decoded_content;
    
    open my $fh, '>', $local
	or croak "Can't create $local: $!";
    print $fh $file;
    close $fh;
}

 sub accuzip_fetch_csv {
    # Returns a qty (int) and a price (float)
    my $guid	= shift;
    
    my $type	= 'csv';
    my $local	= 'AccuZIP_final_file.csv';

    my $url	= $URLS{ download };
    $url	=~ s{#GUID#}{$guid};
    $url	=~ s{#TYPE#}{$type};

    my $ua	= LWP::UserAgent->new;
    if ( not $ua->is_online ) {
	croak "We have no Internet connection! :O";
    }
    $ua->show_progress( 1 );
    
    my $resp    = $ua->get( $url, ':content_file' => $local );
    carp "Error getting status at $url: " . $resp->status_line
	unless $resp->is_success;
    
    my $count	= 0;
    open my $fh, '<', $local
	or croak "Can't open $local: $!";
    $count++ while <$fh>;
    close $fh;
    # Account for the header record
    $count--;
    my $price	= accuzip_price( $count );
    return ( $count, $price );
}
