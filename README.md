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

## How can I run curry with authorization?

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
