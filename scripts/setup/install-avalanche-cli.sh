#!/usr/bin/env bash
# install-avalanche-cli.sh
# Avalanche CLI'ı WSL/Ubuntu'ya kurar. Phase 1 Sprint 3 (ICTT bridge) için ön koşul.
#
# Kullanım:
#   cd /mnt/c/Users/l3eki/Desktop/koza-l1
#   bash scripts/setup/install-avalanche-cli.sh
#
set -euo pipefail

VERSION="v1.9.6"
ASSET="avalanche-cli_1.9.6_linux_amd64.tar.gz"
BASE="https://github.com/ava-labs/avalanche-cli/releases/download"

echo "==> Klasörler hazırlanıyor..."
mkdir -p "$HOME/bin" /tmp/avx

echo "==> Avalanche CLI ${VERSION} indiriliyor..."
curl -L "${BASE}/${VERSION}/${ASSET}" -o /tmp/avx/avx.tar.gz

echo "==> Tarball boyutu:"
ls -la /tmp/avx/avx.tar.gz

echo "==> Tarball açılıyor..."
tar -xzf /tmp/avx/avx.tar.gz -C /tmp/avx/

echo "==> Çıkan dosyalar:"
ls /tmp/avx/

BIN="$(find /tmp/avx -type f -name avalanche | head -1)"
if [ -z "${BIN}" ]; then
    echo "HATA: 'avalanche' binary bulunamadı. Tarball içeriği yukarıda."
    exit 1
fi

echo "==> Binary konumu: ${BIN}"
cp "${BIN}" "$HOME/bin/avalanche"
chmod +x "$HOME/bin/avalanche"

echo "==> Versiyon kontrolü:"
"$HOME/bin/avalanche" --version

# .bashrc'e PATH idempotent ekle
if ! grep -q 'export PATH=\$PATH:\$HOME/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH=$PATH:$HOME/bin' >> "$HOME/.bashrc"
    echo "==> ~/.bashrc'e PATH eklendi (yeni terminal açtığında geçerli olur)"
fi

echo ""
echo "==========================================="
echo "  Kurulum tamamlandı."
echo "  Şu an çalıştırmak için: ~/bin/avalanche --version"
echo "  Yeni terminalde sadece: avalanche --version"
echo "==========================================="
