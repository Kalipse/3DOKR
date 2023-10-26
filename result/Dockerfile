# Dockerfile result



FROM node:18

WORKDIR /app
COPY . /app
COPY ./views /app
RUN npm install
EXPOSE 8888
CMD ["node", "server.js"]
