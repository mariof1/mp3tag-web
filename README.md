# Mp3tag Web

Run [Mp3tag](https://www.mp3tag.de/) in your browser using [GUI Web Base](https://github.com/Aandree5/gui-web-base) (xpra-powered VNC).

Inspired by [picard-web](https://github.com/Aandree5/picard-web).

## Quick Start

```bash
cp example.env .env
# Edit .env with your PUID, PGID, and volume paths
docker compose up -d
```

Then open your browser at: **http://localhost:8080**

## Configuration

Copy `example.env` to `.env` and set:

| Variable         | Description                              | Default   |
|-----------------|------------------------------------------|-----------|
| `PUID`          | User ID the app runs as                  | `1000`    |
| `PGID`          | Group ID the app runs as                 | `1000`    |
| `V_CONFIG_DIR`  | Host path for Mp3tag config persistence  | `./data`  |
| `V_MUSIC_DIR`   | Host path to your music folder           | `./music` |

## Ports

| Container | Host | Protocol |
|-----------|------|----------|
| 5000      | 8080 | HTTP     |

## Building Locally

```bash
docker build -t mp3tag-web .
# or override Mp3tag version:
docker build --build-arg MP3TAG_VERSION=3.33.1 -t mp3tag-web .
```

## Volumes

| Path           | Description                     |
|---------------|---------------------------------|
| `/mp3tag-web` | Mp3tag config and app data      |
| `/music`      | Music files (read/write access) |
