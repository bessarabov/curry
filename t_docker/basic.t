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

sub set {
    my ($path, $status) = @_;

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
            success => JSON::true,
        }),
        'Got expected content',
    );

    return '';
}

sub check_get_object_a_1 {
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

use Data::Dumper;
say Dumper $response;

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


sub main_in_test {
    pass('Loaded ok');

    run_docker();

    set('a.1', 'ok');
    sleep(1);
    set('a.1', 'fail');

    set('a.2', 'ok');
    set('b.1', 'fail');
    set('c.1', 'ok');

    check_get_object_a_1();

    check_get();
    check_get_all();

    check_get_a();
    check_get_all_a();

    rm_docker();

    done_testing();
}
main_in_test();
__END__
