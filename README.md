# show_player (Client-Side Mod)

Un petit CSM pour Luanti/Minetest qui ajoute la commande **.show_player** (et l'alias **.sp**)
pour afficher le **nombre de joueurs connectés** et **leurs noms** dans le chat local.

## Installation

1) Vérifiez que les client-mods sont activés dans votre `minetest.conf` :
```
load_client_mods = true
```
(Optionnel) Si vous avez la sécurité stricte activée, assurez-vous que ce mod n'utilise aucune API restreinte.

2) Copiez le dossier `show_player` dans :
- **Linux** : `~/.minetest/clientmods/`
- **Windows** : `C:\Users\<Vous>\AppData\Roaming\minetest\clientmods\`
- **macOS** : `~/Library/Application Support/minetest/clientmods/`

Arborescence attendue :
```
clientmods/
└── show_player/
    ├── init.lua
    └── mod.conf
```

3) Lancez le jeu, rejoignez un monde/serveur.

## Utilisation

- Tapez **.show_player** dans le chat pour afficher le nombre de joueurs et la liste des pseudos.
- Alias plus court : **.sp**

Le mod segmente la liste des noms sur plusieurs lignes si elle devient trop longue pour le chat.

## Notes

- Ce mod repose sur les API CSM `minetest.get_player_names()` et `minetest.display_chat_message()`.
- Il n’envoie rien au serveur : toutes les infos affichées sont côté client.
