FROM golang:1.19 as build

# The `make build` directive uses this variable
# They will be baked into the built tool 
ARG BUILD_VERSION=docker-unknown

RUN mkdir /go/src/app-build

COPY cmd /go/src/app-build/cmd

COPY go.mod /go/src/app-build/go.mod
COPY go.sum /go/src/app-build/go.sum

COPY Makefile /go/src/app-build/Makefile

WORKDIR /go/src/app-build/

# Alpine requires this, mostly for go test, but i think it's sensible for the 
# rest of the time
ENV CGO_ENABLED 0

RUN make build make-executable

# --- HOT-RELOAD --- #
FROM build as hot-reload

RUN go install github.com/vektra/mockery/v2@latest
RUN go install github.com/cespare/reflex@latest

RUN mkdir /go/src/app-dev
VOLUME /go/src/app-dev

WORKDIR /go/src/app-dev

COPY .local/hot-reload.sh /hot-reload.sh
RUN chmod +x /hot-reload.sh

ENTRYPOINT /hot-reload.sh

# --- FINAL --- #
FROM alpine:latest as final

ARG TARGETARCH

COPY ./dist /tmp/dist

RUN DIST_DIR=/tmp/dist/<< name >>_linux_${TARGETARCH}; if [ "$TARGETARCH" == "amd64" ]; then DIST_DIR="${DIST_DIR}_v1"; fi; mv $DIST_DIR/<< name >> /usr/local/bin/<< name >>

RUN chmod +x /usr/local/bin/<< name >>

RUN rm -rf /tmp/dist

ENTRYPOINT ["/usr/local/bin/<< name >>"]