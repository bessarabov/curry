# Project 'curry'

## What is it?

Project curry is a very simple system for monitoring.

It is a web server that have several endpoints. You can mark the object to be
'ok' or 'fail' with http requests like:

    curl ".../set?path=my_site&status=ok"
    curl ".../set?path=my_other_site&status=fail"

And you can get the current status of your system:

    curl ".../get"

    {
        "status" : "fail",
        "objects" : [
            {
                "path" : "my_other_site",
                "status" : "fail"
            }
        ]
    }

Project curry uses [SemVer](http://semver.org/) for version numbers.

## How can I run curry?

First you need to [install Docker](https://docs.docker.com/installation/).

The second (and the last thing) that you need to do is to run the command:

    docker run --publish 15000:3000 bessarabov/curry:1.0.0

It will download image from [Docker Hub](https://registry.hub.docker.com/u/bessarabov/curry/)
and it will create working instance on port 15000.

This way of running is simple and it allows to play with this project. But
it have on big disadvantage. When you stop the docker instance all the data
is lost. Please read the next section if you need to have persistent storage.

## How can I run curry with persistent storage?

Docker container with curry has sqlite file. All the data that is stored in
curry is stored in that database file. When you delete container that file
is deleted (as it is situated in the container). To make the storage
persistent you need to place that file outsite the docker.

First of all you need to [Docker to be installed](https://docs.docker.com/installation/).

Then you should pull the image:

    docker pull bessarabov/curry:1.0.0

When you have a curry image you can use this commands to copy sqlite file
from the container to your local computer:

    docker run --detach --name tmp_curry bessarabov/curry:1.0.0
    docker cp tmp_curry:/curry/data/db.sqlite .
    docker rm -f tmp_curry

Next you should place db.sqlite to some handy path and run curry mounting
that path to the container. For example if you have placed db.sqlite to
/docker/curry you need to run:

    docker run --volume /docker/curry/:/curry/data/ --publish 15000:3000 bessarabov/curry:1.0.0

This will start curry at port 15000 and it will use database file from your
host computer.

## How can I run curry with authorization?

By default curry has no authorization. Eveybody who has full access to the
curry.

Sometimes you need to limit the access. To do it you should pass environment
variable TOKEN when running docker. Here is an example:

    docker run --publish 15000:3000 -e 'TOKEN=3qagL6jllc' bessarabov/curry:1.0.0

One will not be able to access curry the standard way:

    curl -H "X-Requested-With: XMLHttpRequest" "http://curry:15000/api/1/get"

It will return error:

    {"error_message":"No access","success":false}

To access curry you need to specify that token:

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        -H 'Authorization: TOKEN key="3qagL6jllc"' \
        "http://curry:15000/api/1/get"

And be sure to run curry with persistent storage.

## Statuses

Object in curry has a status. It can be 'ok', 'fail' or 'unknown'. Statuses
'ok' and 'fail' are set manually with API endpoint 'set'. Status 'unknown' is
set to the object automatically when the date of the last 'ok'/'fail' differ
from the current date for the value of 'expire'.

## API

Curry is a webserver. There are several endpoints that you can access. Here
is an example:

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/version"

Here is the answer (the JSON was prettified):

    {
        "success" : true,
        "result" : {
            "version" : "1.0.0"
        }
    }

All API endpoints alwasys return unpretty JSON. All the answers have the same
structure:

    {
        "success" : true,
        "result" : ...
    }

The value "result" can be any valid JSON value: string, number, object,
array, true, false, null. The value of "result" differ for different
endpoints. And "result" is optional.

Here is the sample JSON in case of error:

    {
        "success" : false,
        "error_message" : "Incorrect value for 'path': 'sample path'"
    }

The "error_message" is human readable description of the error.

So, all API endpoints must return JSON. If the endpoint returns not valid
JSON, this means error. The JSON is always an object that hase name
"success". If "success" is a true value then the API request finished
successfully. If the value of "success" is false, this means error and the
description of the error will be in "error_message".

The API is versioned with [SemVer](http://semver.org/). The number in the url
is the Major version of the curry version. Number of API bumps up when the
incompatible API change is made.

## List of API endpoints

### set

With the endpoint "set" you record information about state of the object. You
must specify 2 parameters:

 * path
 * status

Parameter "path" consists of one or more element. Each element is a string
that should match regular exspression [a-z0-9_]+ Elements are separated with
dots. Some examples of valid paths: "aa", "site", "jenkins.job_1"

Parameter "status" can be "ok" or "fail".

When you execute this endpoint with new "path" you must also specify
paramenter "expire". Parameter expire must match regular exspression
[0-9]+[smhd] The meaning of "expire" is in how much time from the last "ok"
or "fail" the object status will be changed to "unknown". The meaning of
postfixes:

 * s — second
 * m — minute
 * h — hour
 * d — day

Sample usage:

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/set?path=aa&status=ok&expire=1d"

It will return:

    {
        "success" : true
    }

### get

Endpoint "get" gives you information of all failed object.

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/get"

It will return:

    {
        "success" : true,
        "result" : {
            "status" : "fail",
            "objects" : [
                {
                    "path" : "bb",
                    "status" : "fail"
                },
                {
                    "path" : "jenkins.job_1",
                    "status" : "fail"
                }
            ]
        }
    }

You can limit the data that "get" returns with the optional parameter "path":

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/get?path=jenkins"

In this example I userd "jenkins" as the value for "path". Such usage will
return all failing objects that has the path starting with "jenkins." and the
"jenkins" object.

    {
        "success" : true,
        "result" : {
            "status" : "fail",
            "objects" : [
                {
                    "path" : "jenkins.job_1",
                    "status" : "fail"
                }
            ]
        }
    }

### get_all

The endpoint "get_all" works exactly as "get", but it returns all the object.

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/get_all"

Here is the example output of this endpoint:

    {
        "success" : true,
        "result" : {
            "status" : "fail",
            "objects" : [
                {
                    "path" : "aa",
                    "status" : "ok"
                },
                {
                    "status" : "fail",
                    "path" : "bb"
                },
                {
                    "path" : "jenkins.job_1",
                    "status" : "fail"
                },
                {
                    "status" : "ok",
                    "path" : "jenkins.job_2"
                }
            ]
        }
    }

Endpoint "get_all" can get optional parameter "path". It works exactly as
in "get" endpoint.

### get_object

Endpoint "get_object" returns all avaliable information about one object.
You must specify parameter "path":

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/get_object?path=aa"

It will return:

    {
        "success" : true,
        "result" : {
            "path" : "aa",
            "status" : "ok",
            "expire" : "1d",
            "history" : [
                {
                    "status" : "ok",
                    "dt" : "2015-01-22 06:33:57"
                },
                {
                    "status" : "ok",
                    "dt" : "2015-01-22 06:40:14"
                }
            ]
        }
    }

### version

Endpoint "version" return the version of the curry system.

    curl \
        -H "X-Requested-With: XMLHttpRequest" \
        "http://curry:15000/api/1/version"

It will return:

    {
        "success" : true,
        "result" : {
            "version" : "1.0.0"
        }
    }

## FAQ

### Why I need to specify X-Requested-With header?

This is a security issue. This heades has beed added to prevent
[CSRF attacks](http://en.wikipedia.org/wiki/Cross-site_request_forgery).

If there was no such header the attacker could add such code on his site:

    <img src="http://curry:15000/api/1/set?path=aa&status=ok"/>

And if you go to that site that it will change she status of the object. To
prevent such situation the header was made obligatory.

### How can I run curry with https?

This is simple. You run curry with docker on some port on localhost and have
nginx (or other web server) that serves https sitet, but passes all requests
to that localhost port.

### What is the future of this project?

For now this project works super well for my purposes. I was thinking about
several things that is good to add to this project, but I don't need that
features heavily. If you need one of this feature or you have any other
feature requests, please write and comment and [GitHub Issues of this
project](https://github.com/bessarabov/curry/issues). Writing at GitHub
will speed up the addition of the features.

Here is the list of features that I think is good to add to this project:

 * endpoint "delete" to delete obsolete objects
 * the ability to specify "never" as "expire" in "set" endpoints
 * the ability to use MySQL as the database
 * the ability to specify how many elements will be stored in history (to
   prevent database of getting very big)
 * hooks — curry could make some http request when the status of the object
   changes
 * make it possible to specify some key-value for every execution of "set"
   endpoint (this can be used to specify some descriptions, for example one
   could set "html" key that has the value of text describing the error in
   detail).

And there are several things that should be changed in this project:

 * Make API more RESTfull — now every endpoint works with GET and POST. We
   should make 'set' work only with POST and all the endpoints that return
   data to work with GET. This is backwards-incompatible change, so the major
   version in SemVer should be bumped.
 * Now every endpoint has must get 'X-Requested-With' header. But actually
   it is needed only for endpoints that changes data (now there is only one
   endpoint 'set'). So we should remove the need of this header for all
   endpoints that just return data ('get', 'get_all', 'get_object',
   'version'). This is backwards-incompatible change, so the major version in
   SemVer should be bumped.
 * Review all the http statuses the endpionts return (especially the
   situations with errors) and change in case something is not consistent
 * Check the situation when you use 'set' endpoint and change only 'expire'
   paramter of the object. Make sure that it works as expected when this
   changes the status of the object to 'unknown'
 * Make sure that the system works in the situation when somebody specifies
   very big value for expire (for example '10000000000000d')

### How can I build docker image myself?

The docker images is build automatically at [Docker Hub](https://registry.hub.docker.com/u/bessarabov/curry/)
but it is pretty easy to build the image yourself:

    git clone https://github.com/bessarabov/curry.git
    cd curry
    docker build --tag curry .

### How to make new release?

This is information for developers of this project. It is a checklist to be
done when releasing new version.

 * Make the changes to the code
 * Run tests `time docker build --tag curry .; prove t_docker/`
 * Find out what SemVer version should be used for new release
 * Change the docs to use new SemVer version number
 * Add list of changes to the Changes file
 * Add git tag
 * Push to GitHub
 * Add new tag to the automated build at Docker Hub

## Publications

 * http://blogs.perl.org/users/ivan_bessarabov/2015/02/using-perl-dancer-and-docker-to-create-simple-monitoring-system.html
 * https://ivan.bessarabov.ru/blog/curry-monitoring (in Russian language)
