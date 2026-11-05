#!/usr/bin/env bash
# Limpeza reversível de uma TV Android TV / Google TV via ADB.
# Nada é desinstalado: os pacotes são apenas DESATIVADOS para o utilizador 0
# e podem ser reativados com "restore".
#
# Uso:
#   ./tv-debloat.sh scan                 # procura dispositivos com ADB na rede (porta 5555)
#   ./tv-debloat.sh connect <IP>         # liga à TV
#   ./tv-debloat.sh backup               # guarda a lista de pacotes e o launcher atual
#   ./tv-debloat.sh candidates           # sugere pacotes (por palavras-chave) para rever
#   ./tv-debloat.sh disable <pacote>...  # desativa pacotes escolhidos por ti
#   ./tv-debloat.sh restore              # reativa tudo o que foi desativado por este script
#   ./tv-debloat.sh disconnect           # desliga o ADB
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$DIR/disabled-packages.txt"
BACKUP_DIR="$DIR/backup"
KEYWORDS='adservice|\.ads|advert|tracking|telemetry|analytics|acr|ota_?update_?ad|promo|sponsor|marketing|recommend'

need() { command -v "$1" >/dev/null || { echo "Falta o comando: $1" >&2; exit 1; }; }
adbsh() { adb shell "$@"; }

cmd="${1:-help}"; shift || true

case "$cmd" in
  scan)
    need nmap
    net="${1:-$(ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | head -1)}"
    [ -n "$net" ] || { echo "Indica a rede, ex: ./tv-debloat.sh scan 192.168.1.0/24"; exit 1; }
    echo "A procurar ADB (porta 5555) em $net ..."
    nmap -p 5555 --open -oG - "$net" | awk '/5555\/open/{print $2}'
    ;;
  connect)
    need adb
    [ $# -ge 1 ] || { echo "Falta o IP da TV."; exit 1; }
    echo "Na TV: Definições > Sistema > Acerca de > clicar 7x em 'Compilação' > Opções de programador > Depuração USB/rede."
    adb connect "$1:5555"
    echo "Aceita o pedido de autorização que aparece na TV."
    adb devices
    ;;
  backup)
    need adb
    mkdir -p "$BACKUP_DIR"
    adbsh pm list packages -f   > "$BACKUP_DIR/packages_all.txt"
    adbsh pm list packages -d   > "$BACKUP_DIR/packages_disabled_before.txt"
    adbsh cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME \
      > "$BACKUP_DIR/home_launcher.txt" || true
    adbsh getprop ro.product.model > "$BACKUP_DIR/model.txt" || true
    echo "Backup guardado em $BACKUP_DIR"
    ;;
  candidates)
    need adb
    echo "Pacotes suspeitos (REVÊ um a um, não desativar às cegas):"
    adbsh pm list packages | sed 's/^package://' | grep -Ei "$KEYWORDS" || echo "(nenhum)"
    echo
    echo "Nunca desativar: com.android.systemui, com.google.android.tvlauncher (até teres outro launcher),"
    echo "com.android.settings, com.google.android.gms, serviços de entrada HDMI/TV (tvinput/tv.input)."
    ;;
  disable)
    need adb
    [ $# -ge 1 ] || { echo "Indica os pacotes a desativar."; exit 1; }
    for p in "$@"; do
      if adbsh pm disable-user --user 0 "$p"; then echo "$p" >> "$LOG"; fi
    done
    ;;
  restore)
    need adb
    [ -f "$LOG" ] || { echo "Nada a restaurar (falta $LOG)."; exit 0; }
    sort -u "$LOG" | while read -r p; do adbsh pm enable "$p"; done
    : > "$LOG"
    echo "Pacotes reativados."
    ;;
  disconnect)
    need adb
    adb disconnect
    echo "Desativa também a depuração nas opções de programador da TV."
    ;;
  *)
    sed -n '2,16p' "$0"
    ;;
esac
