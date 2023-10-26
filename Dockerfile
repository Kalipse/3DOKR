# Dockerfile user

FROM debian:bullseye-slim
RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/user
CMD ["tail", "-f", "/dev/null"]
