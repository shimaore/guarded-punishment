FROM node:alpine as builder

WORKDIR /home/node/app
COPY . ./

RUN npm run build && \
    rm -rf node_modules && \
    npm install && \
    npm cache clean -f && \
    apk add --no-cache tini
USER node
ENTRYPOINT ["/sbin/tini","--","node","server.js"]
