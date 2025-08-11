# 🛡️ Setup Fail2ban pour Debian 12 (SSH)

Script tout-en-un, compatible **/bin/sh (POSIX)** et **ASCII only**, qui :
- installe `fail2ban`, `python3-systemd` et `nftables`,
- detecte automatiquement le port SSH,
- choisit `banaction = nftables` si disponible, sinon `iptables-multiport`,
- utilise `backend = systemd` si possible (sinon `auto`),
- demarre le service et affiche l'etat.

> Objectif: proteger rapidement l'acces SSH d'un serveur Debian 12.

---

## 🚀 Installation rapide

```bash
wget https://raw.githubusercontent.com/floflo530/Fail2ban-SSH/refs/heads/main/setup-fail2ban-ssh.sh
chmod +x setup-fail2ban-ssh.sh
sudo ./setup-fail2ban-ssh.sh
