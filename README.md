[![Pulls on DockerHub](https://img.shields.io/docker/pulls/goosews/cups.svg?style=for-the-badge&label=DockerHub%20pulls&logo=docker)](https://hub.docker.com/r/goosews/cups)
[![Stars on DockerHub](https://img.shields.io/docker/stars/goosews/cups.svg?style=for-the-badge&label=DockerHub%20stars&logo=docker)](https://hub.docker.com/r/goosews/cups)
[![Stars on GitHub](https://img.shields.io/github/stars/goose-ws/cups.svg?style=for-the-badge&label=GitHub%20Stars&logo=github)](https://github.com/goose-ws/cups)

# CUPS Docker Image

## About
This is a fork of [ydkn/docker-cups](https://gitlab.com/ydkn/docker-cups), which includes a script for persistent user management. 

Usernames and passwords will persist across container restarts or rebuilds, as long as the `/etc/cups` directory exists outside the container (as a volume/bind mount).

If you run in to any trouble, please create an issue on [GitHub](https://github.com/goose-ws/docker-cups).

## Usage

### Start the container

I prefer/recommend `docker compose`:
```yaml
services:
  cups:
    container_name: cups
    hostname: cups
    image: goosews/cups:latest
    ports:
      - "631:631"
    environment:
      - "TZ=America/New_York"
    volumes:
      - "/some/persistent/path/cups:/etc/cups"
      - "/etc/localtime:/etc/localtime:ro"
    devices:
      - "/dev/bus/usb:/dev/bus/usb"
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-file: "3"
        max-size: "10M"
```

### Configuration

Login in to CUPS web interface on port 631 (e.g. https://localhost:631) and configure CUPS to your needs.
Default credentials: admin / admin

You can add/remove/edit users and passwords via the `user-management` command. Once the container is running, you can utilize this with the command:

```bash
docker exec -it <container_name> user-management
```