#!/bin/bash

# Use this script to turn the SVG's in state-images/ into PNG's that
# pixlet can display.
#
# Dependencies (mac): `brew install librsvg`

for f in state-images/*; 
  do echo $f; 
  cat $f  | rsvg-convert -h 64  | base64;
done
