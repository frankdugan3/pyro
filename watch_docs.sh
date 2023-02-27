#!/bin/bash

killbg() {
  for p in "${pids[@]}" ; do
    kill "$p";
  done
}

pkill livereload

trap killbg EXIT

pids=()
livereload --wait 2 --target ./priv/static/doc/get-started.html ./priv/static/doc &
pids+=($!)

inotifywait --monitor --recursive --event modify ./lib ./documentation | while read; do
  mix docs --formatter html
done
