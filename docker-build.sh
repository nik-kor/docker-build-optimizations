#!/bin/bash

__START_TIME=$(date +%s)

# "Run image" is used for actually running on hosts
image=$1
# The image for heavy lifting stuff - it makes the artifacts for runtime
buildImage="$image-build"
imageDump="$image.tgz"

echo "Start build for $image"

echo "Building build-image $buildImage"
docker build -t $buildImage .

__BUILD_TIME=$(date +%s)

# We don't need all the layers that were generated during build phase. So we just squash everything into one layer.
# Using docker-export/docker-import.
docker run -d $buildImage tail -f ./build-artifact # `docker export` needs running container
buildContainerId=`docker ps | grep $buildImage | awk '{print $1}'`
echo "Container id running $buildContainerId"
echo "Export docker filesystem"

docker export $buildContainerId > $imageDump # actually, make a dump of the whole container fs
__EXPORT_TIME=$(date +%s)

cat $imageDump | docker import - $image # create a new image(the "Run image") from the dump
rm -rf $imageDump

__IMPORT_TIME=$(date +%s)

docker rm -f $buildContainerId

__END_TIME=$(date +%s)
echo "Build time: $(( $__BUILD_TIME - $__START_TIME ))s"
echo "Export time: $(( $__EXPORT_TIME - $__BUILD_TIME ))s"
echo "Import time: $(( $__END_TIME - $__IMPORT_TIME ))s"
echo "Total time: $(( $__END_TIME - $__START_TIME ))s"
