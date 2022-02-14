FROM alpine:edge
RUN apk update
RUN apk add alpine-sdk
RUN apk add bash
RUN apk add jq
RUN apk add git
RUN apk add openjdk11
RUN apk add apache-ant --update-cache \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
    --allow-untrusted
RUN apk add --update nodejs npm
RUN apk --no-cache upgrade && apk add --no-cache libevent chromium firefox xwininfo xvfb dbus eudev ttf-freefont fluxbox procps tzdata

COPY package-lock.json package.json ./
RUN npm install
COPY . /cyborg

EXPOSE 1337 1338