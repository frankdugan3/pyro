#!/bin/bash

commands=("pyro_components" "pyro_maniac" "pyro_email")
for cmd in "${commands[@]}"; do
  cp ./documentation/suite.md "../$cmd/documentation/"
done
