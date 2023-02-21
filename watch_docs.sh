#!/bin/bash

killbg() {
  for p in "${pids[@]}" ; do
    kill "$p";
  done
}

pkill livereload

trap killbg EXIT

pids=()
livereload --open-url-delay 0 --wait 2 --target ./doc/get-started.html ./doc &
pids+=($!)

inotifywait --monitor --recursive --event modify ./lib ./documentation | while read; do
  mix docs --formatter html
done
