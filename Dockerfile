FROM ubuntu:14.04

ENV UPDATED_AT 2015-01-15

RUN apt-get update

RUN apt-get install -y \
    curl \
    gcc \
    make

RUN curl -L http://cpanmin.us | perl - App::cpanminus

RUN cpanm Dancer

COPY bin/ /curry/bin/
COPY lib/ /curry/lib/

EXPOSE 3000

WORKDIR /curry
CMD perl -Ilib bin/app.psgi
