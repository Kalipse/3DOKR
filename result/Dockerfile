# Dockerfile result

FROM node:18
ENV NODE_ENV production
WORKDIR /app
COPY --chown=user:user . /app
COPY --chown=user:user ./views /app
RUN --mount=type=cache,target=/usr/src/app/.npm \
  npm set cache /usr/src/app/.npm && \  
  npm install ci --only=production
EXPOSE 8888
CMD ["node", "server.js"]

