#!perl

# Internal perl (move to 5.32.0)
use v5.30.0;
use feature 'say';

# Internal perl modules (core)
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use experimental qw(signatures);

# Internal perl modules (debug)
use Data::Dumper;

# External modules
use Carp;
use Acme::CommandCommon;
use POE qw(
    Component::Server::SimpleHTTP
);
use HTTP::Status;

# Version of this software
my $VERSION = '0.001';

my $hostname    =   'digi.paulwebster.org';
my $sessions    =   {};

my $www_interface = POE::Component::Server::SimpleHTTP->new(
        'ALIAS'         =>      'HTTPD',
        'PORT'          =>      11111,
        'HOSTNAME'      =>      $hostname,
        'KEEPALIVE'     =>      1,
        'HANDLERS'      =>      [
            {
                'DIR'           =>      '^/.*',
                'SESSION'       =>      'HTTP_GET',
                'EVENT'         =>      'GOT_MAIN',
            },
            {
                'DIR'           =>      '.*',
                'SESSION'       =>      'HTTP_GET',
                'EVENT'         =>      'GOT_ERROR',
            },
        ],
         'LOGHANDLER' => { 'SESSION' => 'HTTP_GET', 'EVENT'   => 'GOT_LOG' },
         'LOG2HANDLER' => { 'SESSION' => 'HTTP_GET', 'EVENT'   => 'POSTLOG'},
 ) or die 'Unable to create the HTTP Server';
 
# Create our own session to receive events from SimpleHTTP
POE::Session->create(
    inline_states => {
        '_start'        =>      sub {   
            $_[KERNEL]->alias_set( 'HTTP_GET' );
            $_[KERNEL]->post( 'HTTPD', 'GETHANDLERS', $_[SESSION], 'GOT_HANDLERS' );
        },
        'GOT_BAR'       =>      \&GOT_REQ,
        'GOT_MAIN'      =>      \&GOT_REQ,
        'GOT_ERROR'     =>      \&GOT_ERR,
        'GOT_NULL'      =>      \&GOT_NULL,
        'GOT_HANDLERS'  =>      \&GOT_HANDLERS,
        'GOT_LOG'       =>      \&GOT_LOG,
    },
);

exit do { main(); POE::Kernel->run() };

sub main {
    
}

sub web_handler($request, $response) {
     $response->code(RC_OK);
     $response->content("Hi, you fetched ". $request->uri);
     return RC_OK;
}

sub GOT_HANDLERS {
    # ARG0 = HANDLERS array
    my $handlers = $_[ ARG0 ];

    # Move the first handler to the last one
    push( @$handlers, shift( @$handlers ) );

    # Send it off!
    $_[KERNEL]->post( 'HTTPD', 'SETHANDLERS', $handlers );
}
 
sub GOT_NULL {
    # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
    my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

    # Kill this!
    $_[KERNEL]->post( 'HTTPD', 'CLOSE', $response );
}
 
sub GOT_REQ {
    # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
    my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

    # Find the 

    # Do our stuff to HTTP::Response
    $response->code( 200 );
    $response->content( 'Some funky HTML here' );

    # We are done!
    # For speed, you could use $_[KERNEL]->call( ... )
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
 
sub GOT_ERR {
    # ARG0 = HTTP::Request object, ARG1 = HTTP::Response object, ARG2 = the DIR that matched
    my( $request, $response, $dirmatch ) = @_[ ARG0 .. ARG2 ];

    # Check for errors
    if ( ! defined $request ) {
            $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
            return;
    }

    # Do our stuff to HTTP::Response
    $response->code( 404 );
    $response->content( "Hi visitor from " . $response->connection->remote_ip . ", Page not found -> '" . $request->uri->path . "'" );

    # We are done!
    # For speed, you could use $_[KERNEL]->call( ... )
    $_[KERNEL]->post( 'HTTPD', 'DONE', $response );
}
 
sub GOT_LOG {
    # ARG0 = HTTP::Request object, ARG1 = remote IP
    my ($request, $remote_ip) = @_[ARG0,ARG1];

    # Do some sort of logging activity.
    # If the request was malformed, $request = undef
    # CHECK FOR A REQUEST OBJECT BEFORE USING IT.
    if( $request ) {
        warn join(' ', time(), $remote_ip, $request->uri ), "\n";
    } 
    else {
        warn join(' ', time(), $remote_ip, 'Bad request' ), "\n";
    } 
 
    return;
}

sub api_spec {
    
    my $spec = {
        'openapi'   =>  '3.0.3',
        'info'      =>  {
            'title'         =>  'open eReact middleware',
            'description'   =>  'Beta middleware server',
            'termsOfService'=>  "https://$hostname/terms",
            'contact'       =>  {
                'name'          =>  'OpusVL',
                'url'           =>  'https://www.opusvl.com',
                'email'         =>  'support@opusvl.com'
            },
            'license'       =>  {
                'name'          =>  'AGPL 3.0',
                'url'           =>  'https://www.gnu.org/licenses/agpl-3.0.en.html'
            }
        },
        'servers'   =>  [
            'url'           =>  "https://$hostname/api/v3.0.3",
            'description'   =>  'Development server'
        ],
        'paths'     =>  {
            '/test'     =>  {
                'get'       =>  {
                    'description'   =>  'A test handler',
                    'content'       =>  {
                        'application/json'  =>  {
                            'schema'            =>  {
                                'type'              =>  'array'
                            }
                        }
                    }
                }
            }
        },
        'tags'  =>  [
            {
                'name'          =>  'test',
                'description'   =>  'A test handler, i have no damn idea what this is for.',
                'externalDocs'  =>  {
                    'description'   =>  'Find out more',
                    'url'           =>  'http://swagger.io'
                }
            },
        ]
    };

    return $spec;
}