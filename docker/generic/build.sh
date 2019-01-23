#!/usr/bin/env bash

ros_release=$1
base_image=$2

declare -a base_images=(
    "nvidia/cuda:9.0-devel-ubuntu16.04"
    "ubuntu:16.04"
    )

if [ ! -z "$2" ]; then
    if [[ ! " ${base_images[@]} " =~ " $2 " ]]; then
        echo "Error: Base image $2 is not supported. Aborting."
	exit 1
    fi
    base_image_arg="--build-arg docker_base_image=$2"
    echo "Using explicit base image: $2"
fi

# Build Docker Image
if [ "${ros_release}" = "kinetic" ]
then
    echo "Use $1"
    docker build ${base_image_arg} -t autoware-$1 -f Dockerfile.$1 ./../.. --no-cache
else
    echo "Select distribution, kinetic"
fi
