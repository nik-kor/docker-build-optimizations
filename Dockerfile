FROM mhart/alpine-node:4.6

# build stuff
RUN npm install lodash
RUN echo "var _ = require('lodash'); console.log(_.toUpper('hi there!'));" > ./build.js
RUN node build.js > build-artifact

# clean stuff for building environment
RUN rm -rf node_modules && rm -rf ./build.js
