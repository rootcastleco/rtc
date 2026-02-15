# 🎥 Frigate NVR — Netfleet Video Sunucusu

Alma Linux üzerinde **tek komutla** Frigate NVR kurulumu.

## ⚡ Tek Komut Kurulum

```bash
curl -sSL https://raw.githubusercontent.com/rootcastleco/rtc/main/install_frigate.sh | sudo bash
```

## 📋 Ne Kuruluyor?

| Bileşen | Detay |
|---------|-------|
| Docker CE | Engine + Compose Plugin |
| Frigate NVR | `ghcr.io/blakeblackshear/frigate:stable` |
| go2rtc | RTSP/WebRTC proxy (Frigate ile dahili) |
| Firewall | 8971, 5000, 8554, 8555 portları |

## 🌐 Erişim

| Servis | Adres |
|--------|-------|
| Web UI | `http://SUNUCU_IP:8971` |
| RTSP | `rtsp://SUNUCU_IP:8554/<kamera_adi>` |
| WebRTC | port `8555` (tcp/udp) |
| API | `http://SUNUCU_IP:5000` |

## 📹 Kamera Ekleme

Kurulumdan sonra `/opt/frigate/config/config.yml` dosyasını düzenleyin:

```yaml
go2rtc:
  streams:
    arac_01: rtsp://kullanici:sifre@KAMERA_IP:554/stream1
    arac_02: rtsp://kullanici:sifre@KAMERA_IP:554/stream1

cameras:
  arac_01:
    enabled: true
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/arac_01
          roles: [record, detect]
    detect:
      enabled: true
      width: 1280
      height: 720
      fps: 5
    objects:
      track: [person, car, truck, bus]
```

Ardından container'ı yeniden başlatın:

```bash
cd /opt/frigate && docker compose restart
```

## 🔧 Yararlı Komutlar

```bash
# Loglar
docker logs -f frigate

# Durum
docker ps

# Durdur
cd /opt/frigate && docker compose down

# Başlat
cd /opt/frigate && docker compose up -d

# Config düzenle
nano /opt/frigate/config/config.yml
```

## 📁 Dosya Yapısı

```
/opt/frigate/
├── config/
│   └── config.yml          # Frigate yapılandırma
├── storage/                 # Kayıtlar & snapshot'lar
└── docker-compose.yml       # Docker Compose dosyası
```

## Lisans

MIT
