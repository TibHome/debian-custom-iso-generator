FROM ubuntu:24.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xorriso \
        whois \
        isolinux \
        wget \
        curl \
        genisoimage \
        gdisk \
        dosfstools \
        libarchive-tools \
        syslinux-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
# Définir les répertoires utiles
WORKDIR /build

# Copier le script
COPY build_iso.sh .
COPY preseed.cfg .
ADD custom_scripts ./custom_scripts

# Donner les droits d'exécution
RUN chmod +x build_iso.sh

# Point d'entrée du conteneur
ENTRYPOINT ["/bin/sh", "/build/build_iso.sh"]