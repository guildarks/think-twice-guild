# Think Twice — Guild Portal & WoW Addons

## Projet

Portail de guilde WoW pour **Think Twice** (serveur Hyjal-FR).  
Fichier principal : `index.html` (application single-page, vanilla JS + Chart.js).

## Sous-agents disponibles

Des agents spécialisés sont disponibles dans `.claude/agents/` pour le développement d'addons WoW :

| Agent | Utilisation |
|-------|-------------|
| `wow-lua-coder` | Écrire / déboguer du Lua WoW, patterns AceAddon |
| `wow-api-expert` | Trouver les bonnes API WoW, events, structures de données |
| `wow-addon-architect` | Concevoir la structure d'un addon, choisir les libs |
| `wow-ui-designer` | Créer des frames, panels, boutons, tooltips |
| `wow-addon-debugger` | Analyser des erreurs Lua, stack traces, timing |

### Comment les utiliser

Claude Code orchestre automatiquement ces agents selon la tâche. Tu peux aussi les invoquer explicitement :

```
Utilise l'agent wow-lua-coder pour créer un addon qui track la présence au raid
Utilise l'agent wow-api-expert pour trouver comment lire les auras d'un joueur
```

## Stack technique

- **Portail web** : HTML/CSS/JS vanilla, Chart.js, Firebase Firestore
- **Addons WoW** : Lua 5.1, API WoW The War Within (Interface 110007)
- **Bibliothèques addons** : AceAddon-3.0, AceDB-3.0, AceEvent-3.0

## Addons Think Twice planifiés

- `TTG_Attendance` — suivi de présence aux raids
- `TTG_LootCouncil` — gestion du butin
- `TTG_Notes` — notes partagées sur les boss
- `TTG_Recruit` — évaluation des postulants

## Conventions

- Fichiers addon dans `addons/<NomAddon>/`
- Préfixe `TTG_` pour tous les addons de la guilde
- Palette UI : violet `#A78BFA`, rose `#F472B6`, fond `#0A0A0F`
