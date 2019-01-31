#!/bin/bash

function usage() {
    echo "Usage: $0 [-i <image name>] [--cuda <on|ON|off|OFF>]" 1>&2
    exit 1
}

# Defaults
CUDA="on"
IMAGE_NAME="autoware/autoware"
TAG_PREFFIX="local"
ROS_DISTRO="kinetic"

OPTS=`getopt --options c:hi:t: \
	     --long cuda:,help,image-name:,tag-preffix: \
	     --name "$0" -- "$@"`
eval set -- "$OPTS"

while true; do
  case $1 in
  	-c|--cuda)
  	  case "$2" in 
  	  	"on"|"off"|"ON"|"OFF") CUDA="$2" ;;
        *) echo "Invalid option: $2"; exit 1 ;;
  	  esac
      shift 2
      ;;
    -h|--help)
      usage
      exit
      ;;
    -i|--image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
	-t|--tag-preffix)
      TAG_PREFFIX="$2"
      shift 2
      ;;
    --)
      if [ ! -z $2 ]; 
      then
      	echo "Invalid parameter: $2"
      	exit 1
 	  fi
      break
      ;;
    *)
      echo "Invalid option"
      exit 1
      ;;
  esac
done

echo "Building image $IMAGE_NAME using tag_preffix $TAG_PREFFIX, cuda $CUDA, ros $ROS_DISTRO"

BASE=$IMAGE_NAME:$TAG_PREFFIX-$ROS_DISTRO-base

docker build -t $BASE -f Dockerfile.base ./../..

if [ $CUDA = "on" ] || [ $CUDA = "ON" ] ; then
    docker build -t $BASE-cuda --build-arg FROM_ARG=$BASE -f Dockerfile.cuda ./../..
	BASE=$BASE-cuda    
fi

docker build -t $IMAGE_NAME:$TAG_PREFFIX-$ROS_DISTRO --build-arg FROM_ARG=$BASE -f Dockerfile ./../..
