# 3DOCKR

Conteneurisation d'une application de vote distribuée avec Docker

## Sommaire

1. [Introduction](#introduction)
2. [Installtion](#installation)
3. [Conteneurisation des modules](#conteneurisation-des-modules)
4. [Création du Docker Compose](#création-du-docker-compose)
5. [Déploiement sur Docker Swarm](#déploiement-sur-docker-swarm)
6. [Contributeurs](#contributeur)

## Introduction

Ce mini-projet consiste à moderniser le déploiement d'une application distribuée de vote, en utilisant des conteneurs Docker. L'application permet à un public de voter entre deux options et d'afficher les résultats en temps réel. Actuellement, le projet est géré via des scripts bash, et l'objectif est de transformer ce processus en un environnement de conteneurs Docker pour une meilleure gestion, évolutivité et facilité de déploiement.

## Installation

L'installation du projet se fait à partir de GitHub.

1. Vous devez commencer par cloner le projet

```bash
git clone https://github.com/Kalipse/3DOKR.git /3DOKR
```

2. Accéder au dossier du projet

```bash
cd /3DOKR
```

3. Et enfin exécuter une commande Docker Compose.

```bash
docker compose up
```

## Conteneurisation des modules

Pour simplifier le déploiement de l'application, nous avons d'abord converti les scripts bash initiaux associés aux principaux modules (worker, result et vote) en Dockerfiles, en veillant à respecter les meilleures pratiques. Cela nous a permis d'améliorer la gestion des conteneurs et d'assurer une plus grande cohérence.

En ce qui concerne les services Redis et PostgreSQL, nous avons choisi de les intégrer directement dans notre fichier Docker Compose. Cette approche s'est avérée plus simple et plus efficace, car ces services nécessitaient peu de configurations spécifiques et pouvaient être rapidement mis en place dans l'environnement de conteneur.

Ce qui nous donne :

**Module vote (bash) :**

```bash
#!/usr/bin/env bash

# Étape 2 - Vote
# Version de Python utilisée lors des développements : 3.11

cd ../vote || exit

# Installation des dépendances
pip install -r requirements.txt

# Lancement du serveur
python app.py
```

👇

**Module vote (Dockerfile) :**

```Dockerfile
# Dockerfile vote

# Utilisation de l'image Python version 3.11 comme base
FROM python:3.11-alpine

# Définition de la variable d'environnement PYTHON_ENV à "production"
ENV PYTHON_ENV=production

# Définition du répertoire de travail dans le conteneurv
WORKDIR /app

# Copie du fichier requirements.txt du répertoire local dans le répertoire de travail du conteneur
COPY requirements.txt /app/

RUN pip install -r requirements.txt ci --only=production

# Copie de tout le contenu du répertoire local actuel dans le répertoire de travail du conteneur
COPY --chown=user:user . .

# Exposition du port 8080 pour les connexions entrantes
EXPOSE 8080

# Commande à exécuter lorsque le conteneur est lancé
CMD ["python", "app.py"]
```

**Module worker (bash) :**

```bash
#!/usr/bin/env bash

# Étape 4 - Worker
# Version de .NET Core utilisée lors des développements : 7.0

cd ../worker || exit

# Installation des dépendances
dotnet restore

# Production d'un exécutable
dotnet publish -c release --self-contained false --no-restore

# Lancement du serveur
dotnet bin/release/net7.0/Worker.dll
```

👇

**Module worker (Dockerfile) :**

```Dockerfile
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
```

**Module result (bash) :**

```bash
#!/usr/bin/env bash

# Étape 5 - Result
# Version de Node.js utilisée lors des développements : 18

cd ../result || exit

# Installation des dépendances
npm install

# Lancement du serveur
npm start
```

👇

**Module result (Dockerfile) :**

```Dockerfile
# Dockerfile result

# Utilisation de l'image Node.js version 18 comme base
FROM node:18-alpine

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
```

Nous avons également introduit un Dockerfile 'User',qui nous permet de ne pas exécuter les conteneurs en tant qu'utilisateur 'root'. Cette approche renforce la sécurité de notre application en évitant l'exécution de processus sous un privilège élevé

```Dockerfile
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
```

Dans nos fichiers Dockerfile, nous pouvons observer l'application de plusieurs pratiques recommandées, notamment :

- L'utilisation d'une image de base légère

```Dockerfile
FROM node:18-alpine
FROM debian:bullseye-slim
FROM python:3.11-alpine
```

- La définition de l'environnement de production

```Dockerfile
ENV NODE_ENV production
ENV DOTNET_ENV=production
ENV PYTHON_ENV=production
```

- La définition du répertoire de travail

```Dockerfile
WORKDIR /home/user
WORKDIR /app
```

- La copie du contenu local

```Dockerfile
COPY --chown=user:user ./views /app
COPY --from=build --chown=user:user /app/bin/release/net7.0 ./
COPY requirements.txt /app/
```

- La configuration du cache npm

```Dockerfile
RUN --mount=type=cache,target=/usr/src/app/.npm \
npm set cache /usr/src/app/.npm && \
npm install ci --only=production
```

- L'exposition du port

```Dockerfile
EXPOSE 8080
EXPOSE 8888
```

- La gestion des droits d'utilisateur avec `--chown=user:user`

## Création du Docker Compose

Nous avons élaboré un fichier Docker Compose regroupant les trois modules principaux (result, vote, worker), ainsi que les services Redis et PostgreSQL. Nous avons également inclus notre module additionnel, 'user'.

```YAML
# Docker compose

services:
  # Service Redis utilisé pour le stockage en cache
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-volume:/data
    healthcheck:
      test: ["CMD", "sh", "-c", "redis-cli ping | grep -q PONG"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-redis

  # Service PostgreSQL utilisé pour la base de données
  postgres:
    image: postgres:alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-volume:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d postgres"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-postgres

  # Service utilisateur personnalisé
  user:
    build:
      context: .
    healthcheck:
      test: ["CMD", "true"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-user

  # Service de vote
  vote:
    build:
      context: ./vote
    ports:
      - "8080:8080"
    depends_on:
      - redis
    healthcheck:
      test: ["CMD-SHELL", "wget --spider http://localhost:8080 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-redis

  # Worker service qui dépend de Redis et PostgreSQL
  worker:
    build:
      context: ./worker
    depends_on:
      - postgres
      - redis
    healthcheck:
      test: ["CMD", "true"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-redis
      - network-postgres

  # Service de résultat qui dépend du worker
  result:
    build:
      context: ./result
    ports:
      - "8081:8888"
    depends_on:
      - worker
    healthcheck:
      test: ["CMD-SHELL", "wget --spider http://localhost:8888 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-postgres

volumes:
  redis-volume:
    # Volume pour stocker les données Redis
  postgres-volume:
    # Volume pour stocker les données PostgreSQL

networks:
  network-user:
    # Réseau personnalisé pour le service utilisateur
  network-redis:
    # Réseau personnalisé pour les services Redis et Vote
  network-postgres:
    # Réseau personnalisé pour les services PostgreSQL, Worker, et Result
```

En plus d'intégrer nos services, nous avons apporté quatre améliorations pour optimiser davantage notre composition.

1. Réseaux :

- Les réseaux personnalisés nous permettront d'organiser nos conteneurs Docker, permettant ainsi aux conteneurs de communiquer entre eux tout en les isolant les uns des autres.

2. Healthcheck :

- Les tests de santé nous permettront de surveiller l'état des conteneurs et de les relancer si nécessaire. Ces tests seront réalisés à intervalles réguliers et avec un nombre d'essais défini.

3. Volumes :

- Les volumes nous permettront de conserver nos données en mémoire même si le conteneur est supprimé.

4. Depends_on :

- L'attribut depends_on indique à Docker quels conteneurs doivent être opérationnels avant que d'autres puissent démarrer. Dans le code source initial, les scripts Bash devaient être exécutés dans un ordre spécifique pour garantir le fonctionnement de l'application. Ici, nous définissons cet ordre en utilisant cet attribut.

## Déploiement sur Docker Swarm

Pour déployer l'application sur Docker Swarm, nous avons utilisé Vagrant pour gérer efficacement et rapidement les machines virtuelles.

Dans un premier temps, nous avons créé un fichier Vagrant qui a permis de :

- Configurer notre manager et nos deux workers
- Initialiser notre cluster Docker Swarm
- Récupérer le dossier du projet depuis GitHub
- Construire nos différentes images

```Ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

NODES = {
 "manager1" => "192.168.99.100",
 "worker1" => "192.168.99.101",
 "worker2" => "192.168.99.102",
}

Vagrant.configure("2") do |config|
 NODES.each do |(node_name, ip_address)|
   config.vm.define node_name do |node|
     node.vm.box = "bento/ubuntu-20.04"
     node.vm.hostname = node_name
     node.vm.network "private_network", ip: ip_address

     node.vm.provider "virtualbox" do |v|
       v.name = node_name
       v.memory = "1024"
       v.cpus = "1"
     end

     node.vm.provision "shell", inline: <<-SHELL
       # Faire en sorte que les machines puissent communiquer entre elles via leur hostnames (exemple: ping worker1 depuis manager1)
       #{NODES.map{ |n_name, ip| "echo '#{ip} #{n_name}' | sudo tee -a /etc/hosts\n"}.join}

       # Installer Docker
       curl -fsSL get.docker.com -o get-docker.sh
       CHANNEL=stable sh get-docker.sh
       rm get-docker.sh

       # Faire en sorte que le daemon Docker soit accessible depuis l'hôte
       sudo mkdir -p /etc/systemd/system/docker.service.d
       sudo bash -c 'echo -e "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375" > /etc/systemd/system/docker.service.d/options.conf'
       sudo systemctl daemon-reload
       sudo systemctl restart docker.service

     SHELL
     if node_name == "manager1"
       node.vm.provision "shell", inline: <<-SHELL
         # Cloner le dépôt Git
         git clone
         git clone https://github.com/Kalipse/3DOKR.git /3DOKR
         cd /3DOKR

         #build docker image
         docker build -t vote-service ./vote
         docker build -t worker-service ./worker
         docker build -t result-service ./result

         #initialiser le swarm
         docker swarm init --advertise-addr 192.168.99.100

         #il faut ensuite que les workers rejoignent le swarm

         #on peut ensuite deployer les services
         #docker stack deploy --compose-file docker-compose.yml 3DOKR


       SHELL
     end



   end
 end
end
```

Ensuite, nous accédons à chaque worker pour les rejoindre au cluster Docker Swarm.

```bash
vagrant ssh worker1
```

```bash
sudo docker swarm join --token INSERER LE TOKEN + ADDRESSE IP
```

```bash
vagrant ssh worker2
```

```bash
sudo docker swarm join --token INSERER LE TOKEN + ADDRESSE IP
```

Nous modifions ensuite le compose present dans le manager pour inclure l'attribut deploy

```bash
vagrant ssh manager1
```

```YAML
#Docker compose Swarm

version: "3.7"

services:
  # Service Redis utilisé pour le stockage en cache
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-volume:/data
    healthcheck:
      test: ["CMD", "sh", "-c", "redis-cli ping | grep -q PONG"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-redis

  # Service PostgreSQL utilisé pour la base de données
  postgres:
    image: postgres:alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-volume:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d postgres"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-postgres

  # Service utilisateur personnalisé
  user:
    image: user-service:latest
    ports:
      - "8888:8888"
    depends_on:
      - redis
      - postgres
    deploy:
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD", "true"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-user

  # Service de vote
  vote:
    image: vote-service:latest
    ports:
      - "8080:8080"
    depends_on:
      - redis
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD-SHELL", "wget --spider http://localhost:8080 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-redis

  # Worker service qui dépend de Redis et PostgreSQL
  worker:
    image: worker-service:latest
    depends_on:
      - redis
      - postgres
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD", "true"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-redis
      - network-postgres

  # Service de résultat qui dépend du worker
  result:
    image: result-service:latest
    ports:
      - "8081:8888"
    depends_on:
      - worker
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
    healthcheck:
      test: ["CMD-SHELL", "wget --spider http://localhost:8888 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - network-postgres

volumes:
  redis-volume:
    # Volume pour stocker les données Redis
  postgres-volume:
    # Volume pour stocker les données PostgreSQL

networks:
  network-user:
    # Réseau personnalisé pour le service utilisateur
  network-redis:
    # Réseau personnalisé pour les services Redis et Vote
  network-postgres:
    # Réseau personnalisé pour les services PostgreSQL, Worker et Result
```

Il ne nous reste plus qu'à accéder au manager et déployer notre application sur le Docker Swarm.

```bash
docker stack deploy -c SwarmCompose.yaml 3DOKR
```

**Remarque :**

Nous avons aussi modifier les differents noms de services pour y permettre la connexion.

comme par exemple :

```javascript
const pool = new pg.Pool({
  connectionString: "postgres://postgres:postgres@3DOKR_postgres/postgres",
});
```

ou

```cs
var redisConn = OpenRedisConnection("3DOKR_redis");
```

## Contributeurs

Ce projet a été realisé par :

[Noah](https://github.com/Kaalipse)
Et
[Francois Xavier](https://github.com/francoisxavierdesaintjean)
