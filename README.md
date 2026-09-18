# idevice-docker

idevice tools mega pack + backup server in a docker container

# How to use
If you have usbmuxd on your system (reasonable to have by default on a desktop distro), disable it for the current boot before running this container:
```
sudo systemctl mask --runtime --now usbmuxd.service
```

Or disable persistently:
```
sudo systemctl mask --now usbmuxd.service
```

To re-enable:
```
sudo systemctl unmask usbmuxd.service
```

- Build the container image: `docker build -t idevice:latest .`
- Customize the following docker-compose file:
```
services:
  backup-server:
    stdin_open: true
    tty: true
    image: idevice:latest
    network_mode: host
    environment:
      - BACKUP_SERVER=1 # If not set, container drops to shell and runs nothing else
      - BACKUP_TIME=3600
    volumes:
      - ./pairing:/var/lib/lockdown # Pairing records
      - ./backups:/data/idevice-backups # Backups path
      - type: bind
        source: /dev/bus/usb
        target: /dev/bus/usb
    device_cgroup_rules:
      - "c 189:* rmw"
```
- Run: `docker compose up` (foreground) / `docker compose up -d` (background)
