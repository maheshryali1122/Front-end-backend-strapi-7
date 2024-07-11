FROM node:18
ARG PUBLIC_IP=''
WORKDIR /root
RUN apt update && \
    apt install vim -y && \
    git clone https://github.com/maheshryali1122/strapi-frontend-practice-711.git
ENV NODE_OPTIONS="--openssl-legacy-provider"
WORKDIR /root/strapi-frontend-practice-711
RUN sed -i 's|http://ipaddress:1337|http://'$PUBLIC_IP':1337|' /root/strapi-frontend-practice-711/src/App.js
RUN sed -i 's|http://ipaddress:1337|http://'$PUBLIC_IP':1337|' /root/strapi-frontend-practice-711/src/pages/BlogIndex.js

RUN npx update-browserslist-db@latest
RUN npm install --only=prod && \
    npm run build

EXPOSE 3000
CMD [ "npm", "start" ]
