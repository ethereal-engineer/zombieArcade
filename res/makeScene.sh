#!/bin/bash

# Zips a scene up in a compatible manner
# Usage: makeScene.sh SCENE_FOLDER_NAME

rm ./$1.sio2
cd $1
zip -r --no-dir-entries ../$1.sio2 *
