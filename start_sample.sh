#!/bin/sh

# add settings for each system.

#gangreung setting
export MONGO_URL=mongodb://localhost:27017/dasuploader
export _CLIENT_NAME=gangReungSiCheong
export METEOR_OFFLINE_CATALOG=1   #don't update meteor itself
meteor npm --save install oracle@0.3.9
meteor npm install

#meteor --release 1.3.5 -p4000
meteor -p4000