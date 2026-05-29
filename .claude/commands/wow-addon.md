---
description: Crée un addon WoW Think Twice de bout en bout. Coordonne les agents de code uniquement. La doc est générée par /graphify après.
---

Tu vas créer un addon WoW pour la guilde **Think Twice** (Midnight 12.0.5) à partir de cette demande :

**$ARGUMENTS**

Coordonne les agents dans cet ordre, sans t'occuper de documentation (Graphify s'en charge) :

## 1. wow-addon-architect
Structure le projet : `.toc`, arborescence, libs nécessaires.
Crée les fichiers dans `C:\Users\kevin\Desktop\claude\<NomAddon>\`.

## 2. wow-api-expert
Valide toutes les APIs utilisées par l'architect.
Vérifie : Secret Values, CLEU supprimé, comms restreintes, APIs renommées.
Corrige avant de passer à la suite.

## 3. wow-lua-coder
Implémente le code Lua complet dans les fichiers créés par l'architect.
Applique toutes les corrections de l'api-expert.
Respecte : Lua 5.1, préfixe TTG_, palette Think Twice.

## 4. wow-addon-debugger (si erreurs)
Uniquement si wow-lua-coder signale un problème ou une incertitude.
Diagnostique et corrige avant de terminer.

## Fin
Affiche un résumé :
- Fichiers créés et leur chemin
- Règles Midnight appliquées (issecretvalue, UNIT_HEALTH, etc.)
- Commande de test en-game : copier dans `Interface/AddOns/` puis `/reload`
- Rappel : lancer `/graphify .` pour mettre à jour la doc du projet
