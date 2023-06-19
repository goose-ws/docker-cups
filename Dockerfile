# base image
ARG ARCH=amd64
FROM $ARCH/debian:buster-slim

# args
ARG VCS_REF
ARG BUILD_DATE

# environment
ENV ADMIN_PASSWORD=admin

# install packages
RUN apt-get update \
  && apt-get install -y \
  sudo \
  cups \
  cups-bsd \
  cups-filters \
  foomatic-db-compressed-ppds \
  printer-driver-all \
  openprinting-ppds \
  hpijs-ppds \
  hp-ppd \
  hplip \
  dumb-init \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# add print user
RUN adduser --home /home/admin --shell /bin/bash --gecos "admin" --disabled-password admin \
  && adduser admin sudo \
  && adduser admin lp \
  && adduser admin lpadmin

# disable sudo password checking
RUN echo 'admin ALL=(ALL:ALL) ALL' >> /etc/sudoers

# enable access to CUPS
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid) \
  && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# copy /etc/cups for skeleton usage
RUN cp -rp /etc/cups /etc/cups-skel

# set default password for user 'admin' to 'admin'
RUN echo "admin:admin" | chpasswd

# user management script
ADD user-management.bash /usr/local/bin/user-management

# starting command
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
CMD ["dumb-init", "-v", "/usr/local/bin/docker-entrypoint.sh"]

# volumes
VOLUME ["/etc/cups"]

# ports
EXPOSE 631

# healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD pidof cupsd > /dev/null 2>&1