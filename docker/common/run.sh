#!/bin/bash

# Default settings
CUDA="on"
IMAGE_NAME="autoware/autoware"
TAG_PREFIX="local"
ROS_DISTRO="kinetic"
BASE_ONLY="false"

function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "    -b,--base-only        Run the base image only."
    echo "                          Default:$BASE_ONLY"
    echo "    -c,--cuda <on|off>    Enable Cuda support in the Docker."
    echo "                          Default:$CUDA"
    echo "    -h,--help             Display the usage and exit."
    echo "    -i,--image <name>     Set docker images name."
    echo "                          Default:$IMAGE_NAME"
    echo "    -t,--tag-prefix <tag> Tag prefix use for the docker images."
    echo "                          Default:$TAG_PREFIX"
}

OPTS=`getopt --options bc:hi:t: \
         --long base-only,cuda:,help,image-name:,tag-prefix: \
         --name "$0" -- "$@"`
eval set -- "$OPTS"

while true; do
  case $1 in
    -b|--base-only)
      BASE_ONLY="true"
      shift 1
      ;;
    -c|--cuda)
      param=$(echo $2 | tr '[:upper:]' '[:lower:]')
      case "${param}" in
        "on"|"off") CUDA="${param}" ;;
        *) echo "Invalid cuda option: $2"; exit 1 ;;
      esac
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -i|--image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -t|--tag-prefix)
      TAG_PREFIX="$2"
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

echo "Using options:"
echo -e "\tROS distro: $ROS_DISTRO"
echo -e "\tImage name: $IMAGE_NAME"
echo -e "\tTag prefix: $TAG_PREFIX"
echo -e "\tCuda support: $CUDA"
echo -e "\tBase only: $BASE_ONLY"

SUFFIX=""
RUNTIME=""

XSOCK=/tmp/.X11-unix
XAUTH=$HOME/.Xauthority

SHARED_DOCKER_DIR=/home/autoware/shared_dir
SHARED_HOST_DIR=$HOME/shared_dir

AUTOWARE_DOCKER_DIR=/home/autoware/Autoware
AUTOWARE_HOST_DIR=$(realpath ../..)

VOLUMES="--volume=$XSOCK:$XSOCK:rw
         --volume=$XAUTH:$XAUTH:rw
         --volume=$SHARED_HOST_DIR:$SHARED_DOCKER_DIR:rw"

if [ "$BASE_ONLY" == "true" ]; then
    SUFFIX=$SUFFIX"-base"
    VOLUMES="$VOLUMES --volume=$AUTOWARE_HOST_DIR:$AUTOWARE_DOCKER_DIR "
fi

if [ $CUDA == "on" ]; then
    SUFFIX=$SUFFIX"-cuda"
    RUNTIME="--runtime=nvidia"
fi

IMAGE=$IMAGE_NAME:$TAG_PREFIX-$ROS_DISTRO$SUFFIX
echo "Launching $IMAGE"

docker run \
    -it --rm \
    $VOLUMES \
    --env="XAUTHORITY=${XAUTH}" \
    --env="DISPLAY=${DISPLAY}" \
    -u autoware \
    --privileged -v /dev/bus/usb:/dev/bus/usb \
    --net=host \
    $RUNTIME \
    $IMAGE
