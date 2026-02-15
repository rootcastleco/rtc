# 🎥 Frigate NVR — Fleet Video Server

[![npm version](https://img.shields.io/npm/v/frigate-nvr-installer.svg)](https://www.npmjs.com/package/frigate-nvr-installer)
[![npm downloads](https://img.shields.io/npm/dm/frigate-nvr-installer.svg)](https://www.npmjs.com/package/frigate-nvr-installer)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

One-command [Frigate NVR](https://frigate.video/) installer for **Alma Linux** servers. Designed for fleet tracking and surveillance systems.

## ⚡ Quick Install

### Option 1 — npx (recommended)

```bash
sudo npx frigate-nvr-installer
```

### Option 2 — npm global

```bash
sudo npm install -g frigate-nvr-installer
sudo frigate-nvr-installer
```

### Option 3 — curl

```bash
curl -sSL https://raw.githubusercontent.com/rootcastleco/rtc/main/install_frigate.sh | sudo bash
```

## 📋 What Gets Installed

| Component | Details |
|-----------|---------|
| Docker CE | Engine + Compose Plugin |
| Frigate NVR | `ghcr.io/blakeblackshear/frigate:stable` |
| go2rtc | Built-in RTSP/WebRTC proxy |
| Firewall | Ports 8971, 5000, 8554, 8555 opened |

## 🌐 Access Points

| Service | Address |
|---------|---------|
| Web UI | `http://SERVER_IP:8971` |
| RTSP Feeds | `rtsp://SERVER_IP:8554/<camera_name>` |
| WebRTC | port `8555` (tcp/udp) |
| API | `http://SERVER_IP:5000` |

## 📹 Adding Cameras

After installation, edit `/opt/frigate/config/config.yml`:

```yaml
go2rtc:
  streams:
    vehicle_01: rtsp://user:password@CAMERA_IP:554/stream1
    vehicle_02: rtsp://user:password@CAMERA_IP:554/stream1

cameras:
  vehicle_01:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/vehicle_01
          roles: [record, detect]
    detect:
      enabled: true
      width: 1280
      height: 720
      fps: 5
    objects:
      track: [person, car, truck, bus]
```

Then restart the container:

```bash
cd /opt/frigate && docker compose restart
```

## 🔧 Useful Commands

```bash
# View logs
docker logs -f frigate

# Check status
docker ps

# Stop Frigate
cd /opt/frigate && docker compose down

# Start Frigate
cd /opt/frigate && docker compose up -d

# Edit configuration
nano /opt/frigate/config/config.yml
```

## 📁 Directory Structure

```
/opt/frigate/
├── config/
│   └── config.yml           # Frigate configuration
├── storage/                  # Recordings & snapshots
└── docker-compose.yml        # Docker Compose file
```

## Author

**Batuhan Ayrıbaş** — [@rootcastleco](https://github.com/rootcastleco)

## License

MIT
