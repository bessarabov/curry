use strict;
use warnings FATAL => 'all';
use feature 'say';
use utf8;
use open qw(:std :utf8);

use Carp;
use HTTP::Tiny;
use JSON;
use Test::Deep qw(cmp_deeply ignore);
use Test::JSON;
use Test::More;
use Moment;

my $HOST='docker';
my $PORT=12007;

sub run_docker {

    system("docker run --detach --publish $PORT:3000 --name curry curry > /dev/null");

    cmp_ok($?, '==', 0, 'got 0 exit status');

    # need to wait a bit to make container run
    sleep 2;

    return '';
}

sub rm_docker {

    system('docker rm -f curry > /dev/null');

    cmp_ok($?, '==', 0, 'got 0 exit status');

    return '';
}

sub check_version {
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
            success => JSON::true,
            result => {
                version => ignore(),
            },
        },
        'Got expected content from "version"',
    );

    return '';
}

sub check_fail_without_expire {

    my $path = 'sample';
    my $status = 'ok';

    my $url = "http://$HOST:$PORT/api/1/set?path=$path&status=$status";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    is_json(
        $response->{content},
        to_json({
            success => JSON::false,
            error_message => "You must specify 'expire' for this path",
        }),
        'Got expected content',
    );

    return '';
}

sub set {
    my (%params) = @_;

    my $path = delete $params{path};
    my $status = delete $params{status};
    my $expire = delete $params{expire};

    my $expire_text = '';
    if ($expire) {
        $expire_text = "&expire=$expire";
    }

    my $url = "http://$HOST:$PORT/api/1/set?path=$path&status=$status$expire_text";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    is_json(
        $response->{content},
        to_json({
            success => JSON::true,
        }),
        'Got expected content',
    );

    return '';
}

sub first_check_get_object_a_1 {
    my $url = "http://$HOST:$PORT/api/1/get_object?path=a.1";
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
            result => {
                "path" => "a.1",
                "status" => "ok",
                "expire" => '4d',
                "history" => [
                    {
                        "dt" => ignore(),
                        "status" => "ok",
                    },
                ]
            },
        },
        'Got expected content',
    );

    return '';
}

sub second_check_get_object_a_1 {
    my $url = "http://$HOST:$PORT/api/1/get_object?path=a.1";
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
            result => {
                "path" => "a.1",
                "status" => "fail",
                "expire" => '15m',
                "history" => [
                    {
                        "dt" => ignore(),
                        "status" => "ok",
                    },
                    {
                        "dt" => ignore(),
                        "status" => "fail",
                    }
                ]
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get {
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
            success => JSON::true,
            result => {
                "status" => "fail",
                "objects" => [
                    {
                        "path" => "a.1",
                        "status" => "fail"
                    },
                    {
                        "path" => "b.1",
                        "status" => "fail"
                    },
                ],
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get_all {
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
            success => JSON::true,
            result => {
                "status" => "fail",
                "objects" => [
                    {
                        "path" => "a.1",
                        "status" => "fail"
                    },
                    {
                        "path" => "a.2",
                        "status" => "ok"
                    },
                    {
                        "path" => "b.1",
                        "status" => "fail"
                    },
                    {
                        "path" => "c.1",
                        "status" => "ok"
                    },
                ],
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get_a {
    my $url = "http://$HOST:$PORT/api/1/get?path=a";
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
            result => {
                "status" => "fail",
                "objects" => [
                    {
                        "path" => "a.1",
                        "status" => "fail"
                    },
                ],
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get_all_a {
    my $url = "http://$HOST:$PORT/api/1/get_all?path=a";
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
            result => {
                "status" => "fail",
                "objects" => [
                    {
                        "path" => "a.1",
                        "status" => "fail"
                    },
                    {
                        "path" => "a.2",
                        "status" => "ok"
                    },
                ],
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get_d {
    my $url = "http://$HOST:$PORT/api/1/get?path=d";
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
            result => {
                "status" => "fail",
                "objects" => [
                    {
                        "path" => "d.1",
                        "status" => "unknown",
                    },
                ],
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get_all_d {
    my $url = "http://$HOST:$PORT/api/1/get_all?path=d";
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
            result => {
                "status" => "fail",
                "objects" => [
                    {
                        "path" => "d.1",
                        "status" => "unknown"
                    },
                ],
            },
        },
        'Got expected content',
    );

    return '';
}

sub check_get_object_d_1 {
    my $url = "http://$HOST:$PORT/api/1/get_object?path=d.1";
    my $response = HTTP::Tiny->new(
        default_headers => {
            'X-Requested-With' => 'XMLHttpRequest',
        },
    )->get( $url );

    is($response->{status}, 200, 'Got expected http code');

    my $answer = from_json($response->{content});

    cmp_deeply(
        $answer,
        {
            success => JSON::true,
            result => {
                "path" => "d.1",
                "status" => "fail",
                "expire" => '1s',
                "history" => [
                    {
                        "dt" => ignore(),
                        "status" => "ok",
                    },
                    {
                        "dt" => ignore(),
                        "status" => "unknown",
                    },
                ]
            },
        },
        'Got expected content',
    );

    my $delta_seconds =
        Moment->new( dt => $answer->{result}->{history}->[1]->{dt} )->get_timestamp()
        - Moment->new( dt => $answer->{result}->{history}->[0]->{dt} )->get_timestamp()
        ;

    is( $delta_seconds, 1, '2 moments in history differ for 1 second' );

    return '';
}

sub main_in_test {

    pass('Loaded ok');

    run_docker();

    check_version();

    check_fail_without_expire();

    set( path => 'a.1', status => 'ok', expire => '4d' );
    first_check_get_object_a_1();
    sleep(1);
    set( path => 'a.1', status => 'fail', expire => '15m' );
    second_check_get_object_a_1();

    set( path => 'a.2', status => 'ok', expire => '1d');
    set( path => 'b.1', status => 'fail', expire => '1d');
    set( path => 'c.1', status => 'ok', expire => '1d');

    check_get();
    check_get_all();

    check_get_a();
    check_get_all_a();

    set( path => 'd.1', status => 'ok', expire => '1s');
    sleep(2);
    check_get_d();
    check_get_all_d();
    check_get_object_d_1();

    rm_docker();

    done_testing();

}
main_in_test();
__END__
