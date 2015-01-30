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

    docker run --publish 15000:3000 bessarabov/curry

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

    docker pull bessarabov/curry

When you have a curry image you can use this commands to copy sqlite file
from the container to your local computer:

    docker run --detach --name tmp_curry bessarabov/curry
    docker cp tmp_curry:/curry/data/db.sqlite .
    docker rm -f tmp_curry

Next you should place db.sqlite to some handy path and run curry mounting
that path to the container. For example if you have placed db.sqlite to
/docker/curry you need to run:

    docker run --volume /docker/curry/:/curry/data/ --publish 15000:3000 bessarabov/curry

This will start curry at port 15000 and it will use database file from your
host computer.

## How can I run curry with authorization?

By default curry has no authorization. Eveybody who has full access to the
curry.

Sometimes you need to limit the access. To do it you should pass environment
variable TOKEN when running docker. Here is an example:

    docker run --publish 15000:3000 -e 'TOKEN=3qagL6jllc' bessarabov/curry

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
endpoints.

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

### get

### get_all

### get_object

### version

## FAQ

### Why I need to specify X-Requested-With header?

### How can I run curry with https?

### What is the future of this project?

### How can I build docker image myself?
