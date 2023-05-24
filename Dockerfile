# base image
ARG ARCH=amd64
FROM $ARCH/debian:buster-slim

# args
ARG VCS_REF
ARG BUILD_DATE

# environment
ENV ADMIN_PASSWORD=admin

# labels
LABEL maintainer="goose <goose[at]goose[dot]ws>" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.name="goosews/cups" \
  org.label-schema.description="Simple CUPS docker image" \
  org.label-schema.version="0.1" \
  org.label-schema.url="https://hub.docker.com/r/goosews/cups" \
  org.label-schema.vcs-url="https://github.com/goose-ws/docker-cups" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.build-date=$BUILD_DATE

# install packages
RUN apt update
RUN apt install -y sudo cups cups-bsd cups-filters foomatic-db-compressed-ppds printer-driver-all openprinting-ppds hpijs-ppds hp-ppd hplip dumb-init
RUN apt clean
RUN rm -rf /var/lib/apt/lists/*

# add print user
RUN adduser --home /home/admin --shell /bin/bash --gecos "admin" --disabled-password admin
RUN adduser admin sudo
RUN adduser admin lp
RUN adduser admin lpadmin

# disable sudo password checking
RUN echo 'admin ALL=(ALL:ALL) ALL' >> /etc/sudoers

# user management script
ADD user-management.bash /usr/local/bin/user-management
RUN chmod +x /usr/local/bin/user-management

# starting command
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
CMD ["dumb-init", "-v", "/usr/local/bin/docker-entrypoint.sh"]

# volumes
VOLUME ["/etc/cups"]

# ports
EXPOSE 631
