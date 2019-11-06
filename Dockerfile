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
#   STELLAR_SIGNING_PRIVATE_KEY: private rsa key for signing packages
#   STELLAR_SIGNING_PUBLIC_KEY: corresponding public key for private signing key
#   AWS_ACCESS_KEY_ID: AWS access key for uploading packages to s3
#   AWS_SECRET_ACCESS_KEY: AWS secret key for uploading packages to s3
#   S3_BUCKET: S3 bucket to upload packages
#   SKIP_UPLOAD: skip upload to s3
#   PACKAGES: one or more packages to build directly (default: build all terra packages)
FROM alpine:latest as build
ARG STELLAR_SIGNING_PRIVATE_KEY
ARG STELLAR_SIGNING_PUBLIC_KEY
ARG SKIP_UPLOAD
ARG PACKAGES
RUN apk add -U alpine-sdk bash rsync
RUN adduser -s /bin/bash -S build && \
    addgroup build abuild && \
    mkdir -p /etc/apk/keys && \
    echo "$STELLAR_SIGNING_PRIVATE_KEY" > /etc/apk/keys/stellar.rsa && \
    echo "$STELLAR_SIGNING_PUBLIC_KEY" > /etc/apk/keys/stellar.rsa.pub && \
    mkdir -p /home/build/.abuild && \
    echo "PACKAGER_PRIVKEY=\"/etc/apk/keys/stellar.rsa\"" > /home/build/.abuild/abuild.conf
RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories && apk update
COPY . /src
RUN chown -R build /src/terra
USER build
RUN cd /src && \
    if [ -z "$PACKAGES" ]; then export PACKAGES=terra; fi && \
    make $PACKAGES

FROM scratch as package
COPY --from=build /home/build/packages /packages

FROM alpine:latest as upload
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG S3_BUCKET
RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories && apk update
RUN apk add -U s3cmd
COPY --from=package /packages /packages
RUN if [ ! -z "$SKIP_UPLOAD" ]; then s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY \
    sync -P /packages/terra/ s3://$S3_BUCKET; fi

# final scratch image for local export if desired
FROM scratch
COPY --from=upload /packages /
