#!/bin/bash
curl -X POST -H "Content-Type:application/json" \
    'http://admin:password@localhost/_replicate' -d \
    '{"source":"http://isaacs.iriscouch.com/registry/", "target":"registry", "continuous": true}'
