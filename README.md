# 🛡️ Installation & Configuration Automatique de Fail2ban pour Debian 12 (SSH)

Ce projet fournit un script **tout-en-un** qui installe et configure [Fail2ban](https://www.fail2ban.org/) sur **Debian 12**, avec une configuration optimisée pour protéger les connexions **SSH**.  
Il détecte automatiquement le port SSH, applique des paramètres de sécurité robustes et démarre le service.

## 📋 Fonctionnalités

- Installation automatique de Fail2ban
- Détection automatique du port SSH
- Configuration par défaut sécurisée :
  - Bannissement après plusieurs tentatives infructueuses
  - Lecture des logs via `systemd` (plus fiable)
  - Actions via `iptables-nft` (compatible Debian 12)
- Liste blanche par défaut pour localhost et réseaux privés
- Possibilité d’ajouter des IP/CIDR à la liste blanche
- Paramétrage flexible via options en ligne de commande
- Affichage de l’état des jails à la fin

---

## 🚀 Installation

1. **Téléchargez le script**
   ```bash
   wget https://raw.githubusercontent.com/floflo530/Fail2ban-SSH/refs/heads/main/setup-fail2ban-ssh.sh
