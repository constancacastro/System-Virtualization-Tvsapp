FROM node:alpine

WORKDIR /home/node/app

COPY ./app/package.json ./app/package-lock.json ./

RUN npm install

RUN chown -R node:node /home/node

USER node

COPY ./app ./

ENV NODE_PORT=8015
EXPOSE 8015


CMD ["node", "./tvsapp.js"]
