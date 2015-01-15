package Curry::Site;

use Carp;
use Dancer ':syntax';

get '/' => sub {
    return 'Hello, world';
};

true;
