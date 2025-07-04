#!/bin/sh

if [ ! -d ./bin ] || [ ! -d ./bin/release ]; then
    mkdir -p ./bin/relase
fi

ARGS="-out:bin/a.out -debug -o:minimal"
OUT="bin/a.out"

if [ "$1" = "release" ]; then
    ARGS="-out:bin/release/a.out -o:speed"
    OUT="bin/release/a.out"
fi

odin build src $ARGS

if [ "$1" = "run" ]; then
    $OUT
fi
