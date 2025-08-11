#!/usr/bin/env bash
# Installation et configuration de Fail2ban pour Debian 12 (focalisé sur SSH)
# À exécuter en root (sans sudo). Script idempotent.

set -euo pipefail

# ---------- Valeurs par défaut ----------
BANTIME="1h"         # durée de bannissement
FINDTIME="10m"       # fenêtre d'observation des échecs
MAXRETRY="5"         # nombre d'essais avant bannissement
SSH_PORT=""          # détecté automatiquement si vide
IGNORE_IPS=()        # IP/CIDR à mettre en liste blanche

# ---------- Aide ----------
usage() {
  cat <<'EOF'
Usage : setup-fail2ban-ssh.sh [options]

Options :
  --bantime DUREE       Durée du bannissement (défaut : 1h)  ex : 15m, 1h, 24h, 1d
  --findtime DUREE      Fenêtre d'observation (défaut : 10m)
  --maxretry N          Essais autorisés avant ban (défaut : 5)
  --ssh-port PORT       Port SSH (détection auto si omis)
  --ignore-ip IP/CIDR   Ajouter une IP/CIDR en liste blanche (répétable)
  -h, --help            Afficher l’aide

Exemples :
  ./setup-fail2ban-ssh.sh --ignore-ip 1.2.3.4 --ignore-ip 10.0.0.0/8
  ./setup-fail2ban-ssh.sh --bantime 1d --findtime 20m --maxretry 4
EOF
}

# ---------- Contrôles ----------
require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Ce script doit être exécuté en root." >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --bantime)   BANTIME="${2:-}"; shift 2 ;;
      --findtime)  FINDTIME="${2:-}"; shift 2 ;;
      --maxretry)  MAXRETRY="${2:-}"; shift 2 ;;
      --ssh-port)  SSH_PORT="${2:-}"; shift 2 ;;
      --ignore-ip) IGNORE_IPS+=("${2:-}";); shift 2 ;;
      -h|--help)   usage; exit 0 ;;
      *) echo "Option inconnue : $1"; usage; exit 1 ;;
    esac
  done
}

detect_ssh_port() {
  # Si précisé en option, on le garde
  if [[ -n "${SSH_PORT}" ]]; then
    return
  fi
  # Méthode 1 : configuration effective via sshd -T
  if command -v sshd >/dev/null 2>&1; then
    if SSH_PORT_DET=$(sshd -T 2>/dev/null | awk '/^port /{print $2; exit}'); then
      if [[ -n "${SSH_PORT_DET}" ]]; then
        SSH_PORT="${SSH_PORT_DET}"
        return
      fi
    fi
  fi
  # Méthode 2 : lecture de /etc/ssh/sshd_config (dernier Port non commenté)
  if [[ -z "${SSH_PORT}" && -r /etc/ssh/sshd_config ]]; then
    SSH_PORT=$(awk '/^[[:space:]]*Port[[:space:]]+/ {p=$2} END{if(p)print p}' /etc/ssh/sshd_config || true)
  fi
  # Défaut : 22
  [[ -z "${SSH_PORT}" ]] && SSH_PORT="22"
}

join_ignore_ips() {
  local extra=""
  if [[ ${#IGNORE_IPS[@]} -gt 0 ]]; then
    extra=" ${IGNORE_IPS[*]}"
  fi
  # On inclut loopback + réseaux privés par confort
  echo "127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16${extra}"
}

# ---------- Installation ----------
install_fail2ban() {
  echo "Installation de fail2ban…"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y fail2ban
}

# ---------- Configuration ----------
write_config() {
  local ignoreip_all
  ignoreip_all="$(join_ignore_ips)"

  echo "Écriture de /etc/fail2ban/jail.local…"
  install -d -m 0755 /etc/fail2ban
  cat >/etc/fail2ban/jail.local <<EOF
# Fichier généré par setup-fail2ban-ssh.sh
[DEFAULT]
# Unités : s (secondes), m (minutes), h (heures), d (jours)
bantime  = ${BANTIME}
findtime = ${FINDTIME}
maxretry = ${MAXRETRY}

# Liste blanche (IPs/CIDR jamais bannies)
ignoreip = ${ignoreip_all}

# Debian 12 utilise nftables ; préférer iptables-nft
banaction = iptables-nft

# Utiliser journald (plus fiable que les fichiers de log)
backend = systemd

# (Optionnel) Courriels :
# destemail = root@localhost
# sender = fail2ban@$(hostname -f)
# action = %(action_mwl)s

[sshd]
enabled = true
port = ${SSH_PORT}
# Avec backend=systemd, logpath n'est pas nécessaire (lecture du journal)
# filter = sshd  # filtre par défaut
EOF
}

# ---------- Service ----------
enable_and_start() {
  systemctl enable fail2ban >/dev/null 2>&1 || true
  systemctl restart fail2ban
}

# ---------- Affichage d'état ----------
show_status() {
  echo
  echo "État global de Fail2ban :"
  fail2ban-client status || true
  echo
  echo "État de la jail SSHD :"
  fail2ban-client status sshd || true
  echo
  echo "Terminé ✅"
  echo "Commandes utiles :"
  echo "  • IP bannies :               fail2ban-client status sshd"
  echo "  • Débannir une IP :          fail2ban-client set sshd unbanip x.x.x.x"
  echo "  • Logs Fail2ban :            journalctl -u fail2ban --since '1 hour ago'"
}

# ---------- Programme principal ----------
main() {
  require_root
  parse_args "$@"
  detect_ssh_port
  install_fail2ban
  write_config
  enable_and_start
  show_status
}

main "$@"
