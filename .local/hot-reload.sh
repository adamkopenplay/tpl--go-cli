#! /bin/sh

make build
reflex -r '\.go$' make build make-executable