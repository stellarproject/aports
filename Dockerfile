# syntax = docker/dockerfile:experimental
# Copyright 2019 Stellar Project
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Available Build Args:
#   SIGNING_PRIVATE_KEY: private rsa key for signing packages
#   SIGNING_PUBLIC_KEY: corresponding public key for private signing key
#   AWS_ACCESS_KEY_ID: AWS access key for uploading packages to s3
#   AWS_SECRET_ACCESS_KEY: AWS secret key for uploading packages to s3
#   S3_BUCKET: S3 bucket to upload packages
#   SKIP_UPLOAD: skip upload to s3
#   PACKAGES: one or more packages to build directly (default: build all terra packages)
#   PACKAGE_DIR: dest dir for built packages
#   VERSION: git commit for built version
FROM alpine:latest as build
ARG SIGNING_PRIVATE_KEY
ARG SIGNING_PUBLIC_KEY
ARG SKIP_UPLOAD
ARG PACKAGES
ARG PACKAGE_DIR
ARG MIRROR
RUN apk add -U alpine-sdk bash rsync
RUN adduser -u 1000 -s /bin/bash -D build && \
    addgroup build abuild && \
    mkdir -p /etc/apk/keys && \
    echo "$SIGNING_PRIVATE_KEY" > /etc/apk/keys/build.rsa && \
    echo "$SIGNING_PUBLIC_KEY" > /etc/apk/keys/build.rsa.pub && \
    mkdir -p /home/build/.abuild && \
    echo "PACKAGER_PRIVKEY=\"/etc/apk/keys/build.rsa\"" > /home/build/.abuild/abuild.conf
RUN if [ -z "${MIRROR}" ]; then echo "INFO: using default mirror"; export MIRROR="http://dl-cdn.alpinelinux.org/alpine"; fi; printf "${MIRROR}/edge/main\n${MIRROR}/edge/community\n${MIRROR}/edge/testing" > /etc/apk/repositories && apk update
COPY --chown=1000 . /src
RUN mkdir -p /packages && chown -R build /packages
USER build
RUN echo "Building $PACKAGES"
RUN if [ -z "$PACKAGES" ]; then echo "ERR: PACKAGES arg must be specified"; exit 1; fi
RUN --mount=id=packages,type=cache,target=/var/tmp/packages,uid=1000,mode=0777 (cd /src && \
    find /var/tmp/packages -name "APKINDEX.tar.gz" -delete && \
    make PACKAGE_DIR=/var/tmp/packages $PACKAGES; if [ $? -ne 0 ]; then touch /tmp/build-error; fi) || true ; \
    cp -rf /var/tmp/packages / && \
    exit 0
# we exit true above to make sure the cache is always saved.  we check for an error here to notify of build errors
RUN if [ -e /tmp/build-error ]; then echo "ERR: error during package build.  Check logs."; exit 1; fi

# final scratch image for local export if desired
FROM scratch
COPY --from=build /packages /
