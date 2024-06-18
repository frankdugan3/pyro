#!/bin/bash

commands=("pyro_components" "ash_pyro" "ash_pyro_components" "pyro_email")
for cmd in "${commands[@]}"; do
  cp ./documentation/suite.md "../$cmd/documentation/"
done
