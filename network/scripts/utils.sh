#!/bin/bash

# This is a collection of bash functions used by different scripts

# imports
. scripts/envVar.sh

# verify the result of the end-to-end test
verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}
