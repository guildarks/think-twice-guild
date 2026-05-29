---
description: Crée un addon WoW GUILDARKS de bout en bout. Coordonne les agents de code uniquement. La doc est générée par graphify après.
---

Tu vas créer un addon WoW pour la guilde **GUILDARKS** (Midnight 12.0.5) à partir de cette demande :

**$ARGUMENTS**

## ⚠️ RÈGLE ABSOLUE — BRANDING .toc
Dans TOUS les fichiers `.toc` créés ou modifiés, utiliser OBLIGATOIREMENT :
```
## Title: GUILDARKS — |cffA78BFa<NomAddon>|r
## Author: GUILDARKS
```
Ne JAMAIS écrire "Think Twice" dans `## Title` ou `## Author` d'un `.toc`. Jamais.

Coordonne les agents dans cet ordre, sans t'occuper de documentation (Graphify s'en charge) :

## 0. Lire la mémoire Graphify
Si le fichier `graphify-out/GRAPH_REPORT.md` existe, lis-le AVANT de commencer.
Identifie :
- Les patterns Lua déjà validés dans le workspace (réutilise-les)
- Les addons existants et leurs APIs (évite les doublons)
- Les God Nodes (concepts centraux du projet)
Si le fichier n'existe pas encore, continue sans.

## 1. wow-addon-architect
Structure le projet : `.toc`, arborescence, libs nécessaires.
Crée les fichiers dans `C:\Users\kevin\Desktop\claude\<NomAddon>\`.
**Rappel branding** : `## Author: GUILDARKS` et `## Title: GUILDARKS — ...`

## 2. wow-api-expert
Valide toutes les APIs utilisées par l'architect.
Vérifie : Secret Values, CLEU supprimé, comms restreintes, APIs renommées.
Corrige avant de passer à la suite.
**Ne pas modifier le branding du .toc.**

## 3. wow-ui-designer (si UI nécessaire)
Uniquement si l'addon a une interface (fenêtre, boutons, barres...).
Conçoit et code les frames avec la palette Think Twice.
Respecte : InCombatLockdown(), nommage TTG_, ancres relatives.
**Ne pas modifier le branding du .toc.**

## 4. wow-lua-coder
Implémente le code Lua complet dans les fichiers créés par l'architect.
Applique toutes les corrections de l'api-expert.
Respecte : Lua 5.1, préfixe TTG_, palette Think Twice.
**Ne pas modifier le branding du .toc.**

## 5. wow-addon-debugger (si erreurs)
Uniquement si wow-lua-coder signale un problème ou une incertitude.
Diagnostique et corrige avant de terminer.

## Fin — Vérification branding obligatoire
Avant de terminer, vérifie que le fichier `.toc` contient bien :
- `## Author: GUILDARKS` (pas "Think Twice")
- `## Title: GUILDARKS — ...` (pas "Think Twice")
Si ce n'est pas le cas, corrige-le maintenant.

Affiche un résumé :
- Fichiers créés et leur chemin
- Règles Midnight appliquées (issecretvalue, UNIT_HEALTH, etc.)
- Commande de test en-game : copier dans `Interface/AddOns/` puis `/reload`
- Rappel : lancer `graphify .` pour mettre à jour la doc du projet
