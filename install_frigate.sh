#!/bin/bash
###############################################################################
#  Frigate NVR — Alma Linux Tek Komut Kurulum Scripti
#  Netfleet Filo Takip Sistemi Video Sunucusu
#  Hedef Sunucu: 179.60.177.10
#
#  Kullanım:
#    chmod +x install_frigate.sh
#    sudo bash install_frigate.sh
#
#  Kurulumdan sonra:
#    Web UI  → http://179.60.177.10:8971
#    RTSP    → rtsp://179.60.177.10:8554/<kamera_adi>
#    WebRTC  → port 8555 (tcp/udp)
###############################################################################

set -euo pipefail

# ─── Renkler ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# ─── Root kontrolü ─────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    log_err "Bu script root olarak çalıştırılmalıdır!"
    log_info "Kullanım: sudo bash install_frigate.sh"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   🎥  Frigate NVR — Netfleet Video Sunucusu Kurulumu  🎥   ║"
echo "║   Alma Linux • Docker • Frigate Stable                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Değişkenler ────────────────────────────────────────────────────────────
FRIGATE_DIR="/opt/frigate"
CONFIG_DIR="${FRIGATE_DIR}/config"
STORAGE_DIR="${FRIGATE_DIR}/storage"
COMPOSE_FILE="${FRIGATE_DIR}/docker-compose.yml"
CONFIG_FILE="${CONFIG_DIR}/config.yml"
SERVER_IP="179.60.177.10"

###############################################################################
# 1) SİSTEM GÜNCELLEMESİ
###############################################################################
log_info "Adım 1/7 — Sistem güncelleniyor..."
dnf update -y -q
dnf install -y -q dnf-plugins-core curl wget tar
log_ok "Sistem güncellendi."

###############################################################################
# 2) DOCKER KURULUMU
###############################################################################
log_info "Adım 2/7 — Docker kurulumu..."

# Eski Docker paketlerini kaldır
dnf remove -y -q docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc 2>/dev/null || true

# Docker CE repo ekle
if ! dnf repolist | grep -q "docker-ce"; then
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    log_ok "Docker CE repo eklendi."
fi

# Docker kurulumu
dnf install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
log_ok "Docker kuruldu."

# Docker servisini başlat ve enable et
systemctl enable --now docker
log_ok "Docker servisi aktif."

# Docker versiyonlarını göster
docker --version
docker compose version

###############################################################################
# 3) DİZİN YAPISI
###############################################################################
log_info "Adım 3/7 — Dizin yapısı oluşturuluyor..."
mkdir -p "${CONFIG_DIR}"
mkdir -p "${STORAGE_DIR}"
log_ok "Dizinler oluşturuldu: ${FRIGATE_DIR}"

###############################################################################
# 4) FRIGATE CONFIG DOSYASI
###############################################################################
log_info "Adım 4/7 — Frigate config.yml oluşturuluyor..."

cat > "${CONFIG_FILE}" << 'CONFIGEOF'
# ─────────────────────────────────────────────────────────────────────────────
# Frigate NVR — Netfleet Filo Takip Sistemi Yapılandırması
# Düzenlemek için: nano /opt/frigate/config/config.yml
# Düzenledikten sonra Frigate container'ını yeniden başlatın:
#   cd /opt/frigate && docker compose restart frigate
# ─────────────────────────────────────────────────────────────────────────────

# MQTT devre dışı (Home Assistant kullanılmıyor)
mqtt:
  enabled: false

# Dedektör ayarları — CPU (donanım hızlandırıcı yoksa)
detectors:
  cpu1:
    type: cpu
    num_threads: 4

# Kayıt ayarları
record:
  enabled: true
  retain:
    days: 14
    mode: motion
  alerts:
    retain:
      days: 30
  detections:
    retain:
      days: 30
  events:
    retain:
      default: 14

# Anlık görüntü ayarları
snapshots:
  enabled: true
  retain:
    default: 30

# go2rtc ayarları — RTSP ve WebRTC yayınları için
go2rtc:
  streams:
    # ─── Kamera tanımları ──────────────────────
    # Aşağıdaki örnek kamerayı kendi RTSP adreslerinizle değiştirin
    # Her araç kamerası için bir satır ekleyin:
    #
    # arac_01: rtsp://kullanici:sifre@KAMERA_IP:554/stream1
    # arac_02: rtsp://kullanici:sifre@KAMERA_IP:554/stream1
    # arac_03: rtsp://kullanici:sifre@KAMERA_IP:554/stream1

    ornek_kamera: "rtsp://admin:password@192.168.1.100:554/stream1"

# ─── Kamera tanımları ────────────────────────────────────────────────────────
# Her araç kamerası için bir blok ekleyin
cameras:

  # ── ÖRNEK KAMERA (kendi değerlerinizle güncelleyin) ──
  ornek_kamera:
    enabled: true
    ffmpeg:
      inputs:
        # Ana akış — kayıt için (yüksek çözünürlük)
        - path: rtsp://127.0.0.1:8554/ornek_kamera
          roles:
            - record
        # Algılama akışı — düşük çözünürlük, daha az CPU
        - path: rtsp://127.0.0.1:8554/ornek_kamera
          roles:
            - detect
    detect:
      enabled: true
      width: 1280
      height: 720
      fps: 5
    objects:
      track:
        - person
        - car
        - truck
        - bus
        - motorcycle
        - bicycle

  # ── YENİ KAMERA EKLEMEK İÇİN ──
  # 1) Yukarıdaki go2rtc > streams bölümüne RTSP adresini ekleyin
  # 2) Aşağıdaki bloğu kopyalayıp kamera adını değiştirin:
  #
  # arac_01:
  #   enabled: true
  #   ffmpeg:
  #     inputs:
  #       - path: rtsp://127.0.0.1:8554/arac_01
  #         roles:
  #           - record
  #       - path: rtsp://127.0.0.1:8554/arac_01
  #         roles:
  #           - detect
  #   detect:
  #     enabled: true
  #     width: 1280
  #     height: 720
  #     fps: 5
  #   objects:
  #     track:
  #       - person
  #       - car
  #       - truck
CONFIGEOF

log_ok "config.yml oluşturuldu: ${CONFIG_FILE}"

###############################################################################
# 5) DOCKER COMPOSE DOSYASI
###############################################################################
log_info "Adım 5/7 — docker-compose.yml oluşturuluyor..."

cat > "${COMPOSE_FILE}" << COMPOSEEOF
version: "3.9"

services:
  frigate:
    container_name: frigate
    image: ghcr.io/blakeblackshear/frigate:stable
    restart: unless-stopped
    stop_grace_period: 30s
    privileged: true
    shm_size: "512mb"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ${CONFIG_DIR}:/config
      - ${STORAGE_DIR}:/media/frigate
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      # Web UI (authenticated)
      - "8971:8971"
      # Internal API (dikkatli kullanın)
      - "5000:5000"
      # RTSP feeds
      - "8554:8554"
      # WebRTC
      - "8555:8555/tcp"
      - "8555:8555/udp"
    environment:
      FRIGATE_RTSP_PASSWORD: "netfleet2026"
COMPOSEEOF

log_ok "docker-compose.yml oluşturuldu: ${COMPOSE_FILE}"

###############################################################################
# 6) FIREWALL YAPILANDIRMA
###############################################################################
log_info "Adım 6/7 — Firewall yapılandırılıyor..."

if systemctl is-active --quiet firewalld; then
    # Frigate portlarını aç
    firewall-cmd --permanent --add-port=8971/tcp  # Web UI
    firewall-cmd --permanent --add-port=5000/tcp  # API
    firewall-cmd --permanent --add-port=8554/tcp  # RTSP
    firewall-cmd --permanent --add-port=8555/tcp  # WebRTC TCP
    firewall-cmd --permanent --add-port=8555/udp  # WebRTC UDP
    firewall-cmd --reload
    log_ok "Firewall portları açıldı: 8971, 5000, 8554, 8555"
else
    log_warn "firewalld aktif değil, port açma atlanıyor."
    log_info "Eğer iptables kullanıyorsanız portları manuel açmanız gerekir."
fi

###############################################################################
# 7) FRIGATE'İ BAŞLAT
###############################################################################
log_info "Adım 7/7 — Frigate başlatılıyor..."

cd "${FRIGATE_DIR}"
docker compose pull
docker compose up -d

# Container'ın başlamasını bekle
log_info "Container başlaması bekleniyor..."
sleep 10

# Durum kontrolü
if docker ps --filter "name=frigate" --filter "status=running" | grep -q frigate; then
    log_ok "Frigate başarıyla çalışıyor!"
else
    log_warn "Frigate henüz tam başlamadı, logları kontrol edin:"
    log_info "docker logs frigate"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              ✅  KURULUM TAMAMLANDI!  ✅                    ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  🌐 Web UI:   http://${SERVER_IP}:8971              ║"
echo "║  📡 RTSP:     rtsp://${SERVER_IP}:8554/<kamera>     ║"
echo "║  🎥 WebRTC:   port 8555 (tcp/udp)                         ║"
echo "║  🔧 API:      http://${SERVER_IP}:5000              ║"
echo "║                                                            ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  📁 Config:   /opt/frigate/config/config.yml               ║"
echo "║  📁 Kayıtlar: /opt/frigate/storage/                        ║"
echo "║  📁 Compose:  /opt/frigate/docker-compose.yml              ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  🔑 İLK ADIMLAR:                                          ║"
echo "║  1. Web UI'da admin hesabı oluşturun                       ║"
echo "║  2. config.yml'de kamera RTSP adreslerini girin            ║"
echo "║  3. Container'ı yeniden başlatın:                          ║"
echo "║     cd /opt/frigate && docker compose restart               ║"
echo "║                                                            ║"
echo "║  📋 YARARLI KOMUTLAR:                                     ║"
echo "║  • Loglar:      docker logs -f frigate                     ║"
echo "║  • Durum:       docker ps                                  ║"
echo "║  • Durdur:      cd /opt/frigate && docker compose down     ║"
echo "║  • Başlat:      cd /opt/frigate && docker compose up -d    ║"
echo "║  • Config düz.: nano /opt/frigate/config/config.yml        ║"
echo "║                                                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
