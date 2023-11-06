# 3DOCKR

## Description

Ce mini-projet consiste à moderniser le déploiement d'une application distribuée de vote, en utilisant des conteneurs Docker. L'application permet à un public de voter entre deux options et d'afficher les résultats en temps réel. Actuellement, le projet est géré via des scripts bash, et l'objectif est de transformer ce processus en un environnement de conteneurs Docker pour une meilleure gestion, évolutivité et facilité de déploiement.

## Composants

Le projet se compose de trois modules principaux :

1. **vote** : Une application web Python permettant aux utilisateurs de voter pour l'une des deux options. Les votes peuvent être modifiés.

2. **worker** : Un service .NET qui collecte les votes depuis une instance Redis et les stocke dans une base de données PostgreSQL.

3. **result** : Une application web Node.js qui affiche en temps réel les résultats des votes.

## Technologies Utilisées

- Python 3.11 + pip
- Node.js 18 + npm
- SDK .NET Core version 7
- PostgreSQL pour le stockage des votes
- Redis pour la transmission des votes
- Docker pour la conteneurisation des applications

## Processus de Conteneurisation

1. Écriture d'un Dockerfile pour chaque module afin de reproduire le comportement des scripts tout en respectant les meilleures pratiques de conteneurisation.

2. Suppression des scripts ou adaptation pour les rendre compatibles avec Docker.

3. Création d'un fichier Docker Compose regroupant les conteneurs et les bases de données du projet. Déclaration des volumes pour la préservation des données entre les redémarrages, gestion des réseaux et des dépendances, ainsi que la prise en compte des cas où les conteneurs ne démarrent pas.

4. Déploiement de l'application sur un cluster Docker Swarm composé d'un nœud manager et de deux nœuds worker. Un document décrivant le processus de mise en place du cluster et de déploiement de l'application sera fourni.

## Module vote

```Dockerfile
# Dockerfile vote

# Utilisation de l'image Python version 3.11 comme base
FROM python:3.11

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

## Module result

```Dockerfile
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
```

## Module worker

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

## Module user

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

## Docker compose

```yaml
# Docker compose

services:
  # Service Redis utilisé pour le stockage en cache
  redis:
    image: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-volume:/data
    networks:
      - network-redis

  # Service PostgreSQL utilisé pour la base de données
  postgres:
    image: postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-volume:/var/lib/postgresql/data
    networks:
      - network-postgres

  # Service utilisateur personnalisé
  user:
    build:
      context: .
    ports:
      - "8888:8888"
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
    networks:
      - network-redis

  # Service du worker
  worker:
    build:
      context: ./worker
    depends_on:
      - postgres
      - redis
    networks:
      - network-redis
      - network-postgres

  # Service de résultat
  result:
    build:
      context: ./result
    ports:
      - "8081:8888"
    depends_on:
      - worker
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

## Docker Swarm

**Étape 1 : Création du vagrant**

Tout d'abord, nous avons créé un `Vagrantfile` pour définir la configuration de nos machines virtuelles.

```ruby
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

**Étape 2 : Initialisation de Vagrant**

Pour initialiser les machines virtuelles avec Vagrant nous faisons :

```bash
vagrant up
```

**Étape 3 : Initialisation du Nœud Manager**

Une fois les machines virtuelles créées, nous accédons à la machine du nœud manager :

```bash
vagrant ssh manager
```

et nous initialisons le swarm avec :

```bash
docker swarm init --advertise-addr 192.168.99.100
```

**Étape 4 : Initialisation des Nœuds Worker**
Nous accedons ensuite aux machines des nœuds worker :

```bash
vagrant ssh worker1
```

```bash
vagrant ssh worker2
```

et nous les ajoutons au cluster :

```bash
docker swarm join --token VOTRE_TOKEN VOTRE_ADRESSE_IP
```

**Étape 5 : Création du compose**

Nous créons ensuite le compose :

```bash
nano compose.yaml
```

```yaml
#Docker compose Swarm

version: "3.7"

services:
  # Service Redis utilisé pour le stockage en cache
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
    volumes:
      - redis-volume:/data
    networks:
      - network-redis

  # Service PostgreSQL utilisé pour la base de données
  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres-volume:/var/lib/postgresql/data
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
    networks:
      - network-redis

  # Service du worker
  worker:
    image: worker-service:latest
    depends_on:
      - redis
      - postgres
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure
    networks:
      - network-redis
      - network-postgres

  # Service de résultat
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

**Étape 6 : Construction des Images**

Nous construisons nos images pour pouvoir les utiliser dans le deploy :

```bash
docker build -t vote-service ./vote
docker build -t worker-service ./worker
docker build -t result-service ./result
```

**Étape 7 : Déploiement des Services**

Nous déployons ensuite les services :

```bash
docker stack deploy -c compose.yml 3DOKR
```

## Installation et Exécution

### Clonage du Projet et Exécution avec Docker Compose

Pour exécuter ce projet sur votre propre système, suivez les étapes ci-dessous :

**Étape 1 : Clonage du Projet**

Clonez ce dépôt GitHub dans un dossier de votre choix en utilisant la commande `git clone` :

```bash
git clone https://github.com/Kalipse/votre-projet.git
```

**Étape 2 : Accédez au Répertoire du Projet**

Accédez au répertoire du projet nouvellement cloné :

```bash
cd votre-projet
```

**Étape 3 : Lancement de l'Application avec Docker Compose**

Pour lancer l'application à l'aide de Docker Compose, exécutez la commande suivante :

```bash
docker-compose up
```

Docker Compose démarrera les conteneurs pour les modules "vote," "worker," et "result," ainsi que les bases de données PostgreSQL et Redis, selon la configuration définie dans le fichier "docker-compose.yml."

Vous pouvez ensuite accéder à l'application en utilisant un navigateur web à l'adresse `http://localhost`.

**Étape 4 : Arrêt de l'Application**

Pour arrêter l'application et les conteneurs Docker, utilisez la combinaison de touches Ctrl+C dans le terminal où Docker Compose est en cours d'exécution.

Si vous souhaitez personnaliser les ports ou les paramètres, assurez-vous de consulter le fichier "docker-compose.yml" pour effectuer des modifications.

## Contributeurs

Ce projet a été realisé par :

[Noah](https://github.com/Kaalipse)
Et
[Francois Xavier](https://github.com/francoisxavierdesaintjean)
