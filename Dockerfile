FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    git \
    curl

RUN curl -L -o hugo_extended.deb https://github.com/gohugoio/hugo/releases/download/v0.129.0/hugo_extended_0.129.0_linux-arm64.deb \
    && apt-get install -y ./hugo_extended.deb \
    && rm hugo_extended.deb