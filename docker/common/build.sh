#!/bin/bash

echo "========================================================="
echo "Building base"
echo "========================================================="
docker build -t autoware:cpu_kinetic_deps -f ./docker/common/Dockerfile.cpu.kinetic_dependencies . --no-cache

echo "========================================================="
echo "Building Nvidia"
echo "========================================================="
docker build --build-arg FROM_ARG=autoware:cpu_kinetic_deps -t autoware:nvidia_kinetic_deps -f ./docker/common/Dockerfile.nvidia.dependencies . --no-cache

echo "========================================================="
echo "Building all"
echo "========================================================="
docker build --build-arg FROM_ARG=autoware:nvidia_kinetic_deps -t autoware:kinetic_nvidia -f ./docker/common/Dockerfile.autoware . --no-cache
