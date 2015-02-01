use strict;
use warnings FATAL => 'all';
use feature 'say';
use utf8;
use open qw(:std :utf8);

use Carp;
use HTTP::Tiny;
use JSON;
use Test::Deep qw(cmp_deeply ignore);
use Test::More;

my $HOST='docker';
my $PORT=12009;

sub run_docker {

    system("docker run --detach --publish $PORT:3000 --name curry_errors curry > /dev/null");

    cmp_ok($?, '==', 0, 'got 0 exit status');

    # need to wait a bit to make container run
    sleep 2;

    return '';
}

sub rm_docker {

    system('docker rm -f curry_errors > /dev/null');

    cmp_ok($?, '==', 0, 'got 0 exit status');

    return '';
}

sub set_status_ok {
    my $url = "http://$HOST:$PORT/api/1/set?path=a.1&status=ok&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::true,
        },
        'Got expected content',
    );

    return '';
}

sub set_status_fail {
    my $url = "http://$HOST:$PORT/api/1/set?path=a.2&status=fail&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::true,
        },
        'Got expected content',
    );

    return '';
}

sub set_no_status {
    my $url = "http://$HOST:$PORT/api/1/set?path=a.3&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "You must specify 'status'",
        },
        'Got expected content',
    );

    return '';
}

sub set_status_aaa {
    my $url = "http://$HOST:$PORT/api/1/set?path=a.4&status=aaa&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "Incorrect value for 'status': 'aaa'",
        },
        'Got expected content',
    );

    return '';
}

sub set_status_empty {
    my $url = "http://$HOST:$PORT/api/1/set?path=a.4&status&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "Incorrect value for 'status': ''",
        },
        'Got expected content',
    );

    return '';
}

sub set_no_path {
    my $url = "http://$HOST:$PORT/api/1/set?status=ok&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "You must specify 'path'",
        },
        'Got expected content',
    );

    return '';
}

sub check_incorrect_path {
    my ($path) = @_;
    my $url = "http://$HOST:$PORT/api/1/set?path=$path&status=ok&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, "Got expected http code for path '$path'");

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "Incorrect value for 'path': '$path'",
        },
        "Got expected content for path '$path'",
    );

    return '';
}

sub check_correct_path {
    my ($path) = @_;
    my $url = "http://$HOST:$PORT/api/1/set?path=$path&status=ok&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, "Got expected http code for path '$path'");

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::true,
        },
        "Got expected content for path '$path'",
    );

    return '';
}

sub check_incorrect_expire {
    my ($expire) = @_;
    my $url = "http://$HOST:$PORT/api/1/set?path=test&status=ok&expire=$expire";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, "Got expected http code for expire '$expire'");

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "Incorrect value for 'expire': '$expire'",
        },
        "Got expected content for expire '$expire'",
    );

    return '';
}

sub get_object_no_path {
    my $url = "http://$HOST:$PORT/api/1/get_object";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "You must specify 'path'",
        },
        'Got expected content',
    );

    return '';
}

sub get_object_unknown_path {
    my $url = "http://$HOST:$PORT/api/1/get_object?path=no_such_path";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "Parameter 'path' got unknown value 'no_such_path'",
        },
        'Got expected content',
    );

    return '';
}

sub main_in_test {

    pass('Loaded ok');

    run_docker();

    set_status_ok();
    set_status_fail();
    set_no_status();
    set_status_aaa();
    set_status_aaa();
    set_status_empty();

    set_no_path();
    check_incorrect_path('.');
    check_incorrect_path('..');
    check_incorrect_path('*');
    check_incorrect_path('a.');
    check_incorrect_path('.a');

    check_correct_path('__');
    check_correct_path('aaa');
    check_correct_path('aaa.bbb');

    check_incorrect_expire('.');
    check_incorrect_expire('a');
    check_incorrect_expire('79y');
    check_incorrect_expire('never');

    get_object_no_path();
    get_object_unknown_path();

    rm_docker();

    done_testing();

}
main_in_test();
__END__
