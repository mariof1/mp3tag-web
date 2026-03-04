# Mp3tag Web

Run [Mp3tag](https://www.mp3tag.de/) and [Telegram Desktop](https://desktop.telegram.org/) together in your browser using [GUI Web Base](https://github.com/Aandree5/gui-web-base) (xpra-powered).

Both apps open as windows in the **same browser tab** — download music via Telegram, tag it in Mp3tag, then move it to your music library.

Inspired by [picard-web](https://github.com/Aandree5/picard-web).

## Workflow

```
Telegram Desktop  →  /downloads  →  Mp3tag  →  /music
     (download)       (shared folder)  (tag)    (move action)
```

1. Open **http://localhost:8080** — both Mp3tag and Telegram Desktop appear as windows
2. In Telegram, set the download folder to `/downloads` (Settings → Advanced → Download path)
3. Tag your downloaded files in Mp3tag (it opens `/downloads` by default)
4. Run the **"Move to Music"** action in Mp3tag to move tagged files to `/music`

### Setting up the Mp3tag "Move to Music" action

In Mp3tag: **Actions (Quick) → New action group** named `Move to Music`, then add:

| Action type | Setting |
|-------------|---------|
| Move Files  | Destination: `Z:\music` |

Run it with **Alt+6** (or via the Actions menu) after tagging.

## Quick Start

```bash
cp example.env .env
# Edit .env with your PUID, PGID, and volume paths
docker compose up -d
```

Then open: **http://localhost:8080**

## Configuration

| Variable            | Description                                      | Default          |
|--------------------|--------------------------------------------------|------------------|
| `PUID`             | User ID the app runs as                          | `1000`           |
| `PGID`             | Group ID the app runs as                         | `1000`           |
| `INCLUDE_TELEGRAM` | Build arg: install Telegram Desktop              | `true`           |
| `TELEGRAM_ENABLED` | Runtime: launch Telegram at startup              | `true`           |
| `V_CONFIG_DIR`     | Host path for Mp3tag config persistence          | `./data`         |
| `V_MUSIC_DIR`      | Host path to your music library                  | `./music`        |
| `V_DOWNLOADS_DIR`  | Host path for downloads (shared with Telegram)   | `./downloads`    |
| `V_TELEGRAM_DATA`  | Host path to persist Telegram session/settings   | `./telegram-data`|

## Ports

| Container | Host | Protocol |
|-----------|------|----------|
| 5000      | 8080 | HTTP     |

## Volumes

| Path                                      | Description                              |
|------------------------------------------|------------------------------------------|
| `/mp3tag-web`                             | Mp3tag config and app data               |
| `/music`                                  | Final music library (read/write)         |
| `/downloads`                              | Download staging area (shared volume)    |
| `/home/gwb/.local/share/TelegramDesktop` | Telegram session and settings            |

## Building Locally

```bash
# With Telegram (default)
docker compose build

# Without Telegram (smaller image)
INCLUDE_TELEGRAM=false docker compose build

# Override Mp3tag version
docker compose build --build-arg MP3TAG_VERSION=3.33.1
```

## Disabling Telegram at Runtime

To keep Telegram installed in the image but not launch it:

```env
# in .env
TELEGRAM_ENABLED=false
```

