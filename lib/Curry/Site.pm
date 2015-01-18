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

    return {};
};

=head2 /api/1/get_object

=cut

ajax '/api/1/get_object' => sub {

    content_type('application/json');

    my $data = get_db()->get_data(
        'select * from history where path = ?',
        param('path'),
    );

    return JSON::to_json($data);
};

true;
