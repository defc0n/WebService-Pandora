package WebService::Pandora;

use strict;
use warnings;

use WebService::Pandora::Method;
use WebService::Pandora::Cryptor;
use WebService::Pandora::Partner::iOS;

use JSON;
use Data::Dumper;

our $VERSION = '0.1';

### constructor ###

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = {'username' => undef,
                'password' => undef,
                'timeout' => 10,
                'partner' => undef,
                @_};

    # be nice and default to iOS partner if one wasn't given..
    if ( !defined( $self->{'partner'} ) ) {

        $self->{'partner'} = WebService::Pandora::Partner::iOS->new();
    }

    # create and store cryptor object, using the partner's encryption keys
    my $cryptor = WebService::Pandora::Cryptor->new( decryption_key => $self->{'partner'}->decryption_key(),
                                                     encryption_key => $self->{'partner'}->encryption_key() );
    $self->{'cryptor'} = $cryptor;

    bless( $self, $class );

    return $self;
}

### public methods ###

sub login {

    my ( $self ) = @_;

    # first, do the partner login
    my $ret = $self->{'partner'}->login();

    # detect error
    if ( !$ret ) {

        # return the error message from the partner
        $self->error( $self->{'partner'}->error() );
        return;
    }

    # store the important attributes we got back as we'll need them later
    $self->{'partner_auth_token'} = $ret->{'partnerAuthToken'};
    $self->{'partner_id'} = $ret->{'partnerId'};
    $self->{'sync_time'} = $ret->{'syncTime'};

    # handle special case of decrypting the sync time
    $self->{'sync_time'} = $self->{'cryptor'}->decrypt( $self->{'sync_time'} );
    $self->{'sync_time'} = substr( $self->{'sync_time'}, 4 );

    # now create and execute the method for the user login request
    my $method = WebService::Pandora::Method->new( name => 'auth.userLogin',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 1,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'loginType' => 'user',
                                                              'username' => $self->{'username'},
                                                              'password' => $self->{'password'},
                                                              'partnerAuthToken' => $self->{'partner_auth_token'}} );

    $ret = $method->execute();

    # detect error
    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    # store even more attributes we'll need later
    $self->{'user_id'} = $ret->{'userId'};
    $self->{'user_auth_token'} = $ret->{'userAuthToken'};

    # success
    return 1;
}

sub get_station_list {

    my ( $self, %args ) = @_;

    # create the user.getStationList method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'user.getStationList',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub get_station {

    my ( $self, %args ) = @_;

    my $station_token = $args{'station_token'};
    my $include_extended_attributes = $args{'include_extended_attributes'};

    $include_extended_attributes = ( $include_extended_attributes ) ? JSON::true() : JSON::false();

    # create the user.getStation method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'station.getStation',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'stationToken' => $station_token,
                                                              'includeExtendedAttributes' => $include_extended_attributes} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub search {

    my ( $self, %args ) = @_;

    my $search_text = $args{'search_text'};

    # create the music.search method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'music.search',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'searchText' => $search_text} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub get_playlist {

    my ( $self, %args ) = @_;

    my $station_token = $args{'station_token'};

    # create the station.getPlaylist method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'station.getPlaylist',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'stationToken' => $station_token} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub explain_track {

    my ( $self, %args ) = @_;

    my $track_token = $args{'track_token'};

    # create the track.explainTrack method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'track.explainTrack',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'trackToken' => $track_token} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub add_artist_bookmark {

    my ( $self, %args ) = @_;

    my $track_token = $args{'track_token'};

    # create the bookmark.addArtistBookmark method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'bookmark.addArtistBookmark',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'trackToken' => $track_token} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub add_song_bookmark {

    my ( $self, %args ) = @_;

    my $track_token = $args{'track_token'};

    # create the bookmark.addSongBookmark method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'bookmark.addSongBookmark',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'trackToken' => $track_token} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub add_feedback {

    my ( $self, %args ) = @_;

    my $track_token = $args{'track_token'};
    my $is_positive = $args{'is_positive'};

    $is_positive = ( $is_positive ) ? JSON::true() : JSON::false();

    # create the station.addFeedback method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'station.addFeedback',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'trackToken' => $track_token,
							      'isPositive' => $is_positive} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub add_music {

    my ( $self, %args ) = @_;

    my $music_token = $args{'music_token'};
    my $station_token = $args{'station_token'};

    # create the station.addMusic method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'station.addMusic',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => {'musicToken' => $music_token,
							      'stationToken' => $station_token} );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub create_station {

    my ( $self, %args ) = @_;

    my $music_token = $args{'music_token'};
    my $track_token = $args{'track_token'};
    my $music_type = $args{'music_type'};

    my $params = {};

    # did they specify a music token, obtained via search?
    if ( defined( $music_token ) ) {

	$params->{'musicToken'} = $music_token;
    }

    # did they specify a track token, provided from a playlist?
    elsif ( defined( $track_token ) ) {

	# make sure they also specific either song or artist type
	if ( !defined( $music_type ) ) {

	    $self->error( "music_type must be specified (either 'song' or 'artist') when supplying a track token." );
	    return;
	}

	$params->{'trackToken'} = $track_token;
	$params->{'musicType'} = $music_type;
    }

    # they didn't specify either
    else {

	$self->error( "either music_token or track_token must be provided." );
	return;
    }

    # create the station.createStation method w/ appropriate params
    my $method = WebService::Pandora::Method->new( name => 'station.createStation',
                                                   partner_auth_token => $self->{'partner_auth_token'},
                                                   user_auth_token => $self->{'user_auth_token'},
                                                   partner_id => $self->{'partner_id'},
                                                   user_id => $self->{'user_id'},
                                                   sync_time => $self->{'sync_time'},
                                                   host => $self->{'partner'}->host(),
                                                   ssl => 0,
                                                   encrypt => 1,
                                                   cryptor => $self->{'cryptor'},
                                                   timeout => $self->{'timeout'},
                                                   params => $params );

    my $ret = $method->execute();

    if ( !$ret ) {

        $self->error( $method->error() );
        return;
    }

    return $ret;
}

sub error {

    my ( $self, $error ) = @_;

    $self->{'error'} = $error if ( defined( $error ) );

    return $self->{'error'};
}

1;
