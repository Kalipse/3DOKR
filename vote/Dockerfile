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


