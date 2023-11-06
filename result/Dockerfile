# Dockerfile result

# Utilisation de l'image Node.js version 18 comme base
FROM node:18

# Définition de la variable d'environnement NODE_ENV à "production"
ENV NODE_ENV production

# Définition du répertoire de travail dans le conteneur
WORKDIR /app

# Copie de tout le contenu du répertoire local actuel dans le répertoire de travail du conteneur
COPY --chown=user:user . /app

# Copie du répertoire local "views" dans le répertoire de travail du conteneur
COPY --chown=user:user ./views /app

# Configuration du cache npm en utilisant un point de montage
# pour améliorer la vitesse des installations ultérieures
RUN --mount=type=cache,target=/usr/src/app/.npm \
  npm set cache /usr/src/app/.npm && \  
  npm install ci --only=production

# Exposition du port 8888 pour les connexions entrantes
EXPOSE 8888
# Commande à exécuter lorsque le conteneur est lancé
CMD ["node", "server.js"]

