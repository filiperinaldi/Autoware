#!/bin/bash

# Default settings
CUDA="on"
IMAGE_NAME="autoware/autoware"
TAG_PREFIX="local"
ROS_DISTRO="kinetic"
BASE_ONLY="false"
HOST_ARCH=`uname -m`
TARGET_ARCH=`uname -m`

function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "    -b,--base-only        Build the base image(s) only."
    echo "                          Default:$BASE_ONLY"
    echo "    -c,--cuda <on|off>    Enable Cuda support in the Docker."
    echo "                          Default:$CUDA"
    echo "    -h,--help             Display the usage and exit."
    echo "    -i,--image <name>     Set docker images name."
    echo "                          Default:$IMAGE_NAME"
    echo "    -t,--tag-prefix <tag> Tag prefix use for the docker images."
    echo "                          Default:$TAG_PREFIX"
    echo "    --target-arch <x86_64|aarch64> Target CPU architecture. This option allows building a Docker image for a different CPU architecture other than the host's CPU architecture."
    echo "                          Default:$TARGET_ARCH"
}

OPTS=`getopt --options bc:hi:t: \
         --long base-only,cuda:,help,image-name:,tag-prefix:,target-arch: \
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
    --target-arch)
      TARGET_ARCH=$2
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

# Convert CPU architecture to Docker format
function host_to_docker_arch() {
    local host_arch=$1

    if [ "$host_arch" == "x86_64" ]; then
        echo "amd64"
    elif [ "$host_arch" == "aarch64" ]; then
        echo "arm64v8"
    else
        echo "Unknown arch"
        return 1
    fi
    return 0
}

DOCKER_HOST_ARCH=$(host_to_docker_arch $HOST_ARCH)
DOCKER_TARGET_ARCH=$(host_to_docker_arch $TARGET_ARCH)

echo "Using options:"
echo -e "\tROS distro: $ROS_DISTRO"
echo -e "\tImage name: $IMAGE_NAME"
echo -e "\tTag prefix: $TAG_PREFIX"
echo -e "\tCuda support: $CUDA"
echo -e "\tBase only: $BASE_ONLY"
echo -e "\tHost architecture: $HOST_ARCH (Docker: $DOCKER_HOST_ARCH)"
echo -e "\tTarget architecture: $TARGET_ARCH (Docker: $DOCKER_TARGET_ARCH)"

if [ "$HOST_ARCH" != "$TARGET_ARCH" ]; then
    echo "Appending $TARGET_ARCH to the image name..."
    IMAGE_NAME=$IMAGE_NAME/$DOCKER_TARGET_ARCH
fi

BASE=$IMAGE_NAME:$TAG_PREFIX-$ROS_DISTRO-base

docker build \
    --tag $BASE \
    --build-arg ROS_DISTRO=$ROS_DISTRO \
    --build-arg HOST_ARCH=$HOST_ARCH \
    --build-arg DOCKER_HOST_ARCH=$DOCKER_HOST_ARCH \
    --build-arg TARGET_ARCH=$TARGET_ARCH \
    --build-arg DOCKER_TARGET_ARCH=$DOCKER_TARGET_ARCH \
    --file Dockerfile.base ./../..

CUDA_SUFFIX=""
if [ $CUDA == "on" ]; then
    CUDA_SUFFIX="-cuda"
    docker build \
        --tag $BASE$CUDA_SUFFIX \
        --build-arg FROM_ARG=$BASE \
        --file Dockerfile.cuda .
fi

if [ "$BASE_ONLY" == "true" ]; then
    echo "Finished building the base image(s) only."
    exit 0
fi

docker build \
    --tag $IMAGE_NAME:$TAG_PREFIX-$ROS_DISTRO$CUDA_SUFFIX \
    --build-arg FROM_ARG=$BASE$CUDA_SUFFIX \
    --build-arg ROS_DISTRO=$ROS_DISTRO \
    --file Dockerfile ./../..
