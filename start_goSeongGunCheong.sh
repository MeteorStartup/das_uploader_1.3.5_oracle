#!/bin/sh

# add settings for each system.

#gangreung setting
#export MONGO_URL=mongodb://localhost:27017/dasuploader
#export _CLIENT_NAME=gangReungSiCheong
#meteor npm --save install oracle@0.3.9
#meteor npm install
#meteor --release 1.3.5 -p4000
#METEOR_OFFLINE_CATALOG=1 meteor -p4000 #don't update meteor itself 

export MONGO_URL=mongodb://localhost:27017/dasuploader
export _CLIENT_NAME=goSeongGunCheong
export METEOR_OFFLINE_CATALOG=1
#/root/.meteor/packages/meteor-tool/1.3.5/mt-os.linux.x86_64/meteor npm install
/root/.meteor/packages/meteor-tool/1.3.5/mt-os.linux.x86_64/meteor -p4000 --once --release 1.3.5
