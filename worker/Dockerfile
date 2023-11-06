# Dockerfile worker

# Utilisation de l'image .NET SDK version 7.0 comme base pour la construction
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

# Définition de la variable d'environnement DOTNET_ENV à "production"
ENV DOTNET_ENV=production

# Définition du répertoire de travail dans le conteneur
WORKDIR /app

# Copie de tout le contenu du répertoire local actuel dans le répertoire de travail du conteneur
COPY --chown=user:user . ./

# Restauration des dépendances du projet
RUN dotnet restore

# Publication du projet en mode "release" sans restauration
RUN dotnet publish -c release --self-contained false --no-restore

# Utilisation de l'image .NET Runtime version 7.0 comme base pour l'exécution
FROM mcr.microsoft.com/dotnet/runtime:7.0 AS build2

# Définition du répertoire de travail dans le conteneur
WORKDIR /app

# Copie des fichiers publiés à partir de la première étape dans le répertoire de travail de cette étape
COPY --from=build --chown=user:user /app/bin/release/net7.0 ./

# Commande à exécuter lorsque le conteneur est lancé
CMD ["dotnet", "Worker.dll"]

