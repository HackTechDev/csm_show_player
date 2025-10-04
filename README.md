# show_player (Client-Side Mod) — v7

## 🧩 Description

Ce mod **Client-Side** pour **Luanti / Minetest** ajoute :
- Une commande `.show_player` (alias `.sp`) qui affiche le **nombre de joueurs connectés** et **leurs noms**.
- Un **système d’historique global** qui enregistre toutes les commandes envoyées (celles commençant par `.` ou `/`), y compris les **commandes locales** comme `.sp`.

Le mod fonctionne **même si le hook d’envoi de message n’est pas supporté** par votre client, grâce à un système de journal interne.

---

## ⚙️ Installation

1. Activez les **client-mods** dans votre `minetest.conf` :
   ```ini
   load_client_mods = true
   ```
2. Dézippez le dossier `show_player` dans :
   - **Linux :** `~/.minetest/clientmods/`
   - **Windows :** `C:\Users\<Vous>\AppData\Roaming\minetest\clientmods\`
   - **macOS :** `~/Library/Application Support/minetest/clientmods/`

   Arborescence attendue :
   ```
   clientmods/
   └── show_player/
       ├── init.lua
       ├── mod.conf
       └── README.md
   ```

3. (Facultatif) Vérifiez que la sécurité CSM est désactivée pour ce mod si besoin :
   ```ini
   secure.enable_security = false
   ```

---

## 💬 Commandes disponibles

| Commande | Description |
|-----------|-------------|
| `.show_player` / `.sp` | Affiche le nombre de joueurs connectés et leurs noms. |
| `.cmd_history [N]` / `.ch [N]` | Affiche les **N dernières commandes** tapées (par défaut 10, max 200). |
| `.ch_clear` | Efface complètement l’historique des commandes de la session. |

> 💡 Toutes les commandes saisies via `.` ou `/` sont enregistrées dans la session.  
> L’historique **n’est pas persistant** (il disparaît à la fermeture du jeu).

---

## 🧠 Fonctionnement interne

- Le mod intercepte les messages envoyés via :
  - `register_on_sending_chat_message`
  - ou `send_chat_message` (monkey-patch)
- Les commandes locales `.sp`, `.show_player`, `.ch`, etc. sont **explicitement ajoutées à l’historique**, même si le client ne déclenche pas de hook d’envoi.
- L’historique est stocké en mémoire et limité à 200 entrées.

---

## 🧾 Exemple d’utilisation

```
.sp
.show_player
/teleport 0 10 0
.ch
```

Affichera quelque chose comme :
```
[CmdHistory] Dernières 4 commandes :
2025-10-05 00:45:23 — (client) show_player
2025-10-05 00:45:25 — (client) sp
2025-10-05 00:45:27 — (serveur) teleport 0 10 0
2025-10-05 00:45:31 — (client) ch
```

---

## 📦 Version
**v7 — 2025-10-05**  
- Ajout du **journal local garanti** (même sans hook CSM).  
- Historique global `.ch` stable et compatible sur tous clients.  
- Nettoyage complet du code (suppression de l’ancien historique des joueurs).

---

## 👨‍💻 Auteur
Mod développé pour **Luanti (anciennement Minetest)** — par **ChatGPT (GPT-5)** sur demande utilisateur.
