package Curry::Site;

use Carp;
use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Moment;
use SQL::Abstract;
use JSON qw();

use lib::abs qw(
    ../../lib
);
use Curry::DB;

get '/' => sub {
    return 'Hello, world';
};

=head2 /api/1/set

=cut

ajax '/api/1/set' => sub {

    content_type('application/json');

    my $sa = SQL::Abstract->new();

    get_db()->execute(
        $sa->insert(
            'history',
            {
                path => param('path'),
                status => param('status'),
                dt => Moment->now->get_dt(),
            }
        ),
    );

    return JSON::to_json({
         success => JSON::true,
    });
};

=head2 /api/1/get_object

=cut

ajax '/api/1/get_object' => sub {

    content_type('application/json');

    my $data = get_db()->get_data(
        'select dt, status from history where path = ? order by dt',
        param('path'),
    );

    return JSON::to_json({
         success => JSON::true,
         result => {
            status => $data->[-1]->{status},
            path => param('path'),
            history => $data,
        }
    });
};

=head2 /api/1/get

=cut

ajax '/api/1/get' => sub {

    content_type('application/json');

    my $sql_addition = '';
    my @bind = ();
    if (param('path')) {
        $sql_addition = 'where f.path = ? or f.path like ?';
        push @bind,
            param('path'),
            param('path') . ".%",
            ;
    }

    my $data = get_db()->get_data(
        "
        select
            f.path, f.status
        from
            history f
        inner join
            (select max(dt) as max_dt, path from history group by path) s
            on
                f.dt = s.max_dt
                and f.path = s.path
        $sql_addition
        order by
            f.path
        ",
        @bind,
    );

    my $status = 'ok';
    my $objects = [];

    foreach (@{$data}) {
        if ($_->{status} ne 'ok') {
            $status = 'fail';
            push @{$objects}, $_;
        }
    }

    return JSON::to_json({
        success => JSON::true,
        result => {
            status => $status,
            objects => $objects,
        },
    });
};

=head2 /api/1/get_all

=cut

ajax '/api/1/get_all' => sub {

    content_type('application/json');

    my $sql_addition = '';
    my @bind = ();
    if (param('path')) {
        $sql_addition = 'where f.path = ? or f.path like ?';
        push @bind,
            param('path'),
            param('path') . ".%",
            ;
    }

    my $data = get_db()->get_data(
        "
        select
            f.path, f.status
        from
            history f
        inner join
            (select max(dt) as max_dt, path from history group by path) s
            on
                f.dt = s.max_dt
                and f.path = s.path
        $sql_addition
        order by
            f.path
        ",
        @bind,
    );

    my $status = 'ok';
    my $objects = [];

    foreach (@{$data}) {
        if ($_->{status} ne 'ok') {
            $status = 'fail';
        }
        push @{$objects}, $_;
    }

    return JSON::to_json({
        success => JSON::true,
        result => {
            status => $status,
            objects => $objects,
        },
    });
};

true;
