# Dockerfile user

# Utilisation de l'image Debian Bullseye Slim comme base
FROM debian:bullseye-slim

# Création d'un utilisateur "user" avec un shell par défaut (/bin/bash)
RUN useradd -ms /bin/bash user

# Définition de l'utilisateur "user" comme utilisateur par défaut pour les instructions suivantes
USER user

# Définition du répertoire de travail dans le conteneur pour l'utilisateur "user"
WORKDIR /home/user

# Commande à exécuter lorsque le conteneur est lancé (dans ce cas, "tail -f /dev/null" pour maintenir le conteneur actif)
CMD ["tail", "-f", "/dev/null"]

