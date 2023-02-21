#!/bin/sh

if [[ ! -e ./assets/tailwind.phlegethon.colors.json ]]; then
  echo '{}' > ./assets/tailwind.phlegethon.colors.json
fi
