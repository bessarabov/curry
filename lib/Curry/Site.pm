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

=head2 /api/1/version

=cut

ajax '/api/1/version' => sub {

    content_type('application/json');

    return JSON::to_json({
        success => JSON::true,
        result => {
            version => 'dev-1',
        },
    });
};


=head2 /api/1/set

=cut

ajax '/api/1/set' => sub {

    mark_expired();

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

    mark_expired();

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
            status => ($data->[-1]->{status} eq 'ok' ? 'ok' : 'fail'),
            path => param('path'),
            expire => $expire,
            history => $data,
        }
    });
};

=head2 /api/1/get

=cut

ajax '/api/1/get' => sub {

    mark_expired();

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

    mark_expired();

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

sub mark_expired {

    my $settings = get_db()->get_data(
        'select path, `value` from settings where type = "expire"',
    );

    my $path2expire = { map { $_->{path} => expire2seconds($_->{value})} @{$settings} };
#$VAR1 = {
#          'c.1' => 86400,
#          'a.1' => 300,
#          'a.2' => 86400,
#          'b.1' => 86400,
#          'd.1' => 1
#        };

    my $history = get_db()->get_data(
        "
        select
            f.path, f.status, s.max_dt
        from
            history f
        inner join
            (select max(dt) as max_dt, path from history group by path) s
            on
                f.dt = s.max_dt
                and f.path = s.path
        order by
            f.path
        ",
    );
#$VAR1 = [
#          {
#            'path' => 'a.1',
#            'max_dt' => '2015-01-20 09:43:26',
#            'status' => 'ok'
#          },
#          {
#            'path' => 'a.2',
#            'status' => 'ok',
#            'max_dt' => '2015-01-20 09:41:54'
#          },

    my $sa = SQL::Abstract->new();
    my $now = Moment->now();

    foreach my $element (@{$history}) {

        my $path = $element->{path};

        my $max_dt_moment = Moment->new( dt => $element->{max_dt} );
        my $expire_dt_moment = $max_dt_moment->plus( second => $path2expire->{$path} );

        if ( $now->get_timestamp() >= $expire_dt_moment->get_timestamp() ) {
            if ($element->{status} ne 'unknown') {

                get_db()->execute(
                    $sa->insert(
                        'history',
                        {
                            path => $path,
                            status => 'unknown',
                            dt => $expire_dt_moment->get_dt(),
                        }
                    ),
                );
            }
        }

    }

}

sub expire2seconds {
    my ($expire) = @_;

    croak 'expire is not defined' if not defined $expire;

    my $seconds;

    if ($expire =~ /^([0-9]+)([smhd])$/) {
        my %multiplier = (
            s => 1,
            m => 60,
            h => 3600,
            d => 86400,
        );

        $seconds = $1 * $multiplier{$2};
    } else {
        croak sprintf("expire %s is in unknown format", $expire);
    }

    return $seconds;
}

true;
