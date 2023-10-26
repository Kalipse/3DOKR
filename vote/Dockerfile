# Dockerfile vote

FROM python:3.11
ENV PYTHON_ENV=production
WORKDIR /app
COPY requirements.txt /app/
RUN pip install -r requirements.txt ci --only=production
COPY --chown=user:user . .
EXPOSE 8080
CMD ["python", "app.py"]


