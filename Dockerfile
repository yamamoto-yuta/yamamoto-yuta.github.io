FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    git \
    curl

COPY .hugo_version /tmp/.hugo_version

RUN HUGO_VERSION=$(cat /tmp/.hugo_version) \
    && curl -L -o hugo_extended.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-arm64.deb \
    && apt-get install -y ./hugo_extended.deb \
    && rm hugo_extended.deb /tmp/.hugo_version