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

    my $has_expire_setting = get_db()->get_one(
        "select count(*)
        from settings
        where path = ? and type = 'expire'",
        param('path'),
    );

    if (defined param('expire')) {

        if ($has_expire_setting) {

            get_db()->execute(
                $sa->update(
                    'settings',
                    {
                        value => param('expire'),
                    },
                    {
                        path => param('path'),
                        type => 'expire',
                    },
                ),
            );

        } else {

            get_db()->execute(
                $sa->insert(
                    'settings',
                    {
                        path => param('path'),
                        type => 'expire',
                        value => param('expire'),
                    }
                ),
            );

        }

    } else {

        if (not $has_expire_setting) {
            return JSON::to_json({
                 success => JSON::false,
                 error_message => "You must specify 'expire' for this path",
            });
        }
    }

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

    my $expire = get_db()->get_one(
        'select value from settings where path = ? and type = "expire"',
        param('path'),
    );

    my $data = get_db()->get_data(
        'select dt, status from history where path = ? order by dt',
        param('path'),
    );

    return JSON::to_json({
         success => JSON::true,
         result => {
            status => $data->[-1]->{status},
            path => param('path'),
            expire => $expire,
            history => $data,
        }
    });
};

=head2 /api/1/get

=cut

ajax '/api/1/get' => sub {

    content_type('application/json');

    return JSON::to_json({
        success => JSON::true,
        result => get_data(
            path => param('path'),
            type => 'get',
        ),
    });
};

=head2 /api/1/get_all

=cut

ajax '/api/1/get_all' => sub {

    content_type('application/json');

    return JSON::to_json({
        success => JSON::true,
        result => get_data(
            path => param('path'),
            type => 'get_all',
        ),
    });
};

sub get_data {
    my (%params) = @_;

    my $path = delete $params{path};
    my $type = delete $params{type};

    my $sql_addition = '';
    my @bind = ();
    if ($path) {
        $sql_addition = 'where f.path = ? or f.path like ?';
        push @bind,
            $path,
            $path . ".%",
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
            push @{$objects}, $_ if $type eq 'get',
        }
        push @{$objects}, $_ if $type eq 'get_all',
    }

    my $result = {
        status => $status,
        objects => $objects,
    };

    return $result;
}

true;
