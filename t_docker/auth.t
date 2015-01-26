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
my $PORT=12008;

sub run_docker {

    system("docker run --detach --publish $PORT:3000 -e 'TOKEN=3B3I6ptQIqrH' --name curry_auth curry > /dev/null");

    cmp_ok($?, '==', 0, 'got 0 exit status');

    # need to wait a bit to make container run
    sleep 2;

    return '';
}

sub rm_docker {

    system('docker rm -f curry_auth > /dev/null');

    cmp_ok($?, '==', 0, 'got 0 exit status');

    return '';
}

sub check_set_is_not_working {
    my $url = "http://$HOST:$PORT/api/1/set?path=a&status=ok&expire=8h";
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
            error_message => "No access",
        },
        'Got expected content',
    );

    return '';
}

sub check_version_is_not_working {
    my $url = "http://$HOST:$PORT/api/1/version";
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
            error_message => "No access",
        },
        'Got expected content',
    );

    return '';
}

sub check_get_is_not_working {
    my $url = "http://$HOST:$PORT/api/1/get";
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
            error_message => "No access",
        },
        'Got expected content',
    );

    return '';
}

sub check_get_all_is_not_working {
    my $url = "http://$HOST:$PORT/api/1/get_all";
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
            error_message => "No access",
        },
        'Got expected content',
    );

    return '';
}

sub check_get_object_is_not_working {
    my $url = "http://$HOST:$PORT/api/1/get_object?path=a";
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
            error_message => "No access",
        },
        'Got expected content',
    );

    return '';
}

sub check_set_is_not_working_with_incorrect_token {
    my $url = "http://$HOST:$PORT/api/1/set?path=a&status=ok&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
            'Authorization' => 'TOKEN key="123"',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    cmp_deeply(
        from_json($response->{content}),
        {
            success => JSON::false,
            error_message => "No access",
        },
        'Got expected content',
    );

    return '';
}

sub check_set_is_working_with_correct_token {
    my $url = "http://$HOST:$PORT/api/1/set?path=a&status=ok&expire=8h";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
            'Authorization' => 'TOKEN key="3B3I6ptQIqrH"',
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

sub main_in_test {

    pass('Loaded ok');

    run_docker();

    check_set_is_not_working();
    check_version_is_not_working();
    check_get_is_not_working();
    check_get_all_is_not_working();
    check_get_object_is_not_working();

    check_set_is_not_working_with_incorrect_token();

    check_set_is_working_with_correct_token();

    rm_docker();

    done_testing();

}
main_in_test();
__END__
