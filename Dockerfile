FROM alpine:latest as build
ARG STELLAR_SIGNING_PRIVATE_KEY
ARG STELLAR_SIGNING_PUBLIC_KEY
RUN apk add -U alpine-sdk bash
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
    make terra

FROM scratch as package
COPY --from=build /home/build/packages /packages

FROM alpine:latest
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG S3_BUCKET
RUN printf "http://dl-cdn.alpinelinux.org/alpine/edge/main\nhttp://dl-cdn.alpinelinux.org/alpine/edge/community\nhttp://dl-cdn.alpinelinux.org/alpine/edge/testing" > /etc/apk/repositories && apk update
RUN apk add -U s3cmd
COPY --from=package /packages /packages
RUN s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY \
    sync -P /packages/terra/ s3://$S3_BUCKET

# final scratch image for local export if desired
FROM scratch
COPY --from=package /packages /
