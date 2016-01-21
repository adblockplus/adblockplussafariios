#!/bin/sh

DOWNLOAD_FOLDER=$1

CORE_SUBFOLDER=core
mkdir $CORE_SUBFOLDER

for LOCFOLDER in $DOWNLOAD_FOLDER/*; do
  if [ -d "$LOCFOLDER" ]; then
    pushd $LOCFOLDER > /dev/null
    LOC_CODE=${PWD##*/}
    echo $LOC_CODE
    popd > /dev/null
    cp $LOCFOLDER/en.xliff ./$LOC_CODE.xliff
  fi
done
