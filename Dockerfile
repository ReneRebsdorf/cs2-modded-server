FROM debian:bullseye-20240211-slim

USER root

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
    sudo \
    dnsutils \
    curl \
    git-all \
    ca-certificates=20210119 \
    lib32z1=1:1.2.11.dfsg-2+deb11u2 \
    wget=1.21-1+deb11u1 \
    locales \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup steam \
    && useradd -g steam steam

ENV TICKRATE=""
ENV MAXPLAYERS=""
ENV API_KEY=""
ENV STEAM_ACCOUNT=""

COPY ./install_docker.sh /home/steam/
COPY ./custom_files/ /home/steam/
COPY ./game/ /home/steam/

RUN mkdir /home/steam/steamcmd

RUN chown -R steam:steam /home/steam
RUN chmod -R 701 /home/steam

WORKDIR /home/steam

USER steam

ENTRYPOINT /home/steam/install_docker.sh
