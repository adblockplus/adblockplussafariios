#!/bin/sh

UNPACKDIR=unpack
mkdir $UNPACKDIR

for PACKAGE in ./*.zip; do
  FILENAME=$(basename $PACKAGE)
  LANGCODE=${FILENAME%.*}
  echo $LANGCODE
  unzip $PACKAGE -d $UNPACKDIR
  mv $UNPACKDIR/en.xliff $LANGCODE.xliff
done
