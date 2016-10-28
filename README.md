# Docker build optimizations

The aim of this micro project is to depict the way how to optimize your build process with Docker.
Btw it's not perfect and have to be rethink.

## Dockerfile example

Here is the content of Dockerfile:
```dockerfile
FROM mhart/alpine-node:4.6

# 1. build stuff
RUN npm install lodash
# some 'useful' steps
RUN echo "var _ = require('lodash'); console.log(_.toUpper('hi there!'));" > ./build.js
RUN node build.js > build-artifact

# 2. clean stuff for building environment
RUN rm -rf node_modules && rm -rf ./build.js
```
We can divide the process of building into building the artifact and removing useless libraries and tools.
The `build-artifact` is the only thing that we need in the final image.

## The problem

The problem is in the intermediate layers:
```bash
➜  docker-build-optimizations git:(master) ✗ docker history my-image
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
5af424c456c9        16 hours ago        /bin/sh -c rm -rf node_modules && rm -rf ./bu   0 B
8914c03d630a        16 hours ago        /bin/sh -c node build.js > build-artifact       9 B
f7ecf6c407d7        16 hours ago        /bin/sh -c echo "var _ = require('lodash'); c   63 B
d3237dc0b157        16 hours ago        /bin/sh -c npm install lodash                   2.162 MB
dfcbae5ded73        10 days ago         /bin/sh -c apk add --no-cache curl make gcc g   31.34 MB
<missing>           10 days ago         /bin/sh -c #(nop)  ENV VERSION=v4.6.1 NPM_VER   0 B
<missing>           5 weeks ago         /bin/sh -c #(nop) ADD file:d6ee3ba7a4d59b1619   4.803 MB
```
We don't need `d3237dc0b157`, `f7ecf6c407d7` and `8914c03d630a`.

## The solution

The one way to solve this issue is to remove this intermediate layers by using `docker export/import` commands.
For more details see `docker-build.sh` script.

```bash
➜  docker-build-optimizations git:(master) ✗ ./docker-build.sh my-image
```

```bash
➜  docker-build-optimizations git:(master) ✗ docker history my-image
IMAGE               CREATED             CREATED BY          SIZE                COMMENT
166d57395cd8        16 hours ago                            36.9 MB             Imported from -
```

## The downsides and the really good solution

So now there is one very small layer and everything in it. Is it perfect? - No. Because in this case Docker cannot
cache pulled layers and have to download almost the same stuff every time.

The one solution that seems nice is [Rocker's from overloading](https://github.com/grammarly/rocker#from).
Of course you can archieve the same effect with a simple bash-script but it won't be so obvious.
