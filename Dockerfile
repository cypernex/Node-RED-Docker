FROM node:lts as build

RUN apt-get update \
  && apt-get install -y build-essential python perl-modules

RUN deluser --remove-home node \
  && useradd --gid 0 --uid 1000 --shell /bin/bash --create-home nodered

USER 1000

RUN sudo mkdir -p .node-red/data

WORKDIR .node-red/data

COPY ./package.json .node-red/data/
RUN npm install

## Release image
FROM node:lts-slim

RUN apt-get update && apt-get install -y perl-modules && rm -rf /var/lib/apt/lists/*

RUN deluser --remove-home node \
  && useradd --gid 0 --uid 1000 --shell /bin/bash --create-home nodered

USER 1000



COPY ./server.js .node-red/data/
COPY ./settings.js .node-red/data/
COPY ./flows.json /.node-red/data/
COPY ./flows_cred.json /.node-red/data/
COPY ./package.json /.node-red/data/
COPY --from=build /.node-red/data/node_modules /.node-red/data/node_modules

USER 0

RUN chgrp -R 0 /.node-red/data \
  && chmod -R g=u /.node-red/data

USER 1000

WORKDIR /.node-red/data

ENV PORT 1880
ENV NODE_ENV=production
ENV NODE_PATH=/data/node_modules
EXPOSE 1880

CMD ["node", "/.node-red/data/server.js", "/.node-red/data/flows.json"]
