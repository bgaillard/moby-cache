FROM alpine AS build-assets-less
WORKDIR /var/www/gdc

COPY assets/less/package.json assets/less/
RUN mkdir -p assets/less/node_modules && echo "FAKE" > assets/less/node_modules/FAKE

FROM alpine AS build-node-modules
WORKDIR /var/www/gdc

COPY package*.json .npmrc ./
COPY assets/js/react/package*.json assets/js/react/

RUN mkdir -p assets/js/react/node_modules && echo "FAKE" > assets/js/react/node_modules/FAKE
RUN mkdir -p node_modules && echo "FAKE" > node_modules/FAKE

FROM alpine AS build-php
WORKDIR /var/www/gdc

COPY --from=build-node-modules /var/www/gdc/node_modules /var/www/gdc/node_modules

FROM alpine AS build-public
WORKDIR /var/www/gdc

COPY *.config.js package*.json ./
COPY assets assets

RUN mkdir -p public/build_ssr && echo "FAKE" > public/build_ssr/FAKE

COPY --from=build-assets-less /var/www/gdc/assets/less/node_modules /var/www/gdc/assets/less/node_modules
COPY --from=build-node-modules /var/www/gdc/node_modules /var/www/gdc/node_modules
COPY --from=build-node-modules /var/www/gdc/assets/js/react/node_modules /var/www/gdc/assets/js/react/node_modules

FROM alpine as website-ssr

COPY --from=build-public /var/www/gdc/public/build_ssr  /var/www/gdc/public/build_ssr
COPY js js
