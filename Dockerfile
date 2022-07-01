FROM golang:<< go_version >>-alpine as build

# The `make build` directive uses this variable
# They will be baked into the built tool 
ARG BUILD_VERSION=docker-unknown

RUN mkdir /go/src/app-build

COPY go.mod /go/src/app-build/go.mod
COPY go.sum /go/src/app-build/go.sum

COPY main.go /go/src/app-build/main.go

COPY Makefile /go/src/app-build/Makefile

WORKDIR /go/src/app-build/

# Alpine requires this, mostly for go test, but i think it's sensible for the 
# rest of the time
ENV CGO_ENABLED 0

RUN apk add make
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

COPY --from=build /go/bin/<< name >> /usr/local/bin/<< name >>
RUN chmod +x /usr/local/bin/<< name >>

ENTRYPOINT ["/usr/local/bin/<< name >>"]