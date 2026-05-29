# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace

Ce dossier (`C:\Users\kevin\Desktop\claude`) est le **workspace de développement d'addons WoW** pour la guilde **Think Twice** (serveur Hyjal-FR).

Chaque addon vit dans son propre sous-dossier à la racine du workspace.

**Tous les nouveaux addons créés doivent être placés directement sous `C:\Users\kevin\Desktop\claude\<NomAddon>\`.**

## Documentation automatique avec Graphify

La documentation du projet est générée automatiquement par **Graphify** — pas besoin de l'écrire manuellement.

### Générer / mettre à jour la doc
```bash
graphify .
```
Graphify analyse tout le code du workspace et génère `graphify-out/GRAPH_REPORT.md`.

### Lire la doc (pour les agents)
Avant de coder ou debugger, les agents lisent `graphify-out/GRAPH_REPORT.md` pour :
- Réutiliser les patterns Lua déjà validés
- Éviter de recréer des APIs déjà existantes
- Identifier les God Nodes (concepts centraux du projet)

### Workflow recommandé
1. Créer / modifier l'addon avec `/wow-addon <description>`
2. Lancer `graphify .` dans le terminal pour mettre à jour la doc
3. Committer le dossier `graphify-out/` avec le code

## Branding des addons

**IMPORTANT** : Dans tous les fichiers `.toc`, utiliser obligatoirement :
- `## Title: GUILDARKS — |cffA78BFa<NomAddon>|r`
- `## Author: GUILDARKS`

Ne jamais écrire "Think Twice" dans `## Title` ou `## Author` d'un `.toc`.
"Think Twice" est le nom de la guilde — le nom d'auteur dans les addons est **GUILDARKS**.

## Cible technique

- **Version WoW** : Midnight 12.0.5
- **Interface .toc** : `## Interface: 120005`
- **Lua** : 5.1 (pas de `goto`, pas de `//`, pas de bitwise `&|~`)
- **Préfixe addon guilde** : `TTG_` pour tous les outils de la guilde Think Twice

## Règles critiques Midnight 12.0 — à appliquer systématiquement

1. **Secret Values** : toute opération arithmétique ou comparaison sur `UnitHealth`, `UnitPower`, données d'aura en combat doit être protégée par `issecretvalue()`.
2. **CLEU supprimé** : `COMBAT_LOG_EVENT_UNFILTERED` n'existe plus. Remplacer par `UNIT_HEALTH`, `UNIT_AURA`, `ENCOUNTER_START`, `ENCOUNTER_END`.
3. **Comms restreintes** : `SendAddonMessage` / `AceComm` bloqué en encounter, M+, PvP. Toujours vérifier `IsCommRestricted()` et queue les messages, flush sur `ENCOUNTER_END`.
4. **InCombatLockdown()** obligatoire avant toute modification de frame/attribut en combat.
5. **APIs renommées** : `C_Spell.GetSpellInfo` (pas `GetSpellInfo`), `C_Item.GetItemInfo`, `C_Container.GetContainerItemInfo`, `C_UnitAuras.GetAuraDataByIndex` (pas `UnitAura`).

## Palette graphique Think Twice

À utiliser pour toute UI (cohérence avec le portail web de la guilde) :

```lua
local ACCENT     = {0.65, 0.55, 0.98}        -- #A78BFA violet électrique
local ACCENT_DIM = {0.55, 0.36, 0.96}        -- #8B5CF6
local PINK       = {0.96, 0.45, 0.71}        -- #F472B6
local BG_DARK    = {0.04, 0.04, 0.06, 0.95}  -- #0A0A0F
```

## Structure d'addon recommandée

### Minimal
```
<NomAddon>/
├── <NomAddon>.toc
├── <NomAddon>.lua
└── README.md
```

### Complet (AceAddon)
```
<NomAddon>/
├── <NomAddon>.toc
├── Core.lua            -- :OnInitialize, :OnEnable
├── Config.lua          -- AceConfig
├── GUI.lua             -- interface
├── Modules/
├── Locale/ (frFR.lua, enUS.lua)
└── Libs/ (LibStub, Ace3)
```

### .toc type
```ini
## Interface: 120005
## Title: GUILDARKS — |cffA78BFa<Nom>|r
## Author: GUILDARKS
## Version: 1.0.0
## SavedVariables: <Nom>DB
## SavedVariablesPerCharacter: <Nom>CharDB
```

## Agents Claude disponibles pour ce workspace

Pour créer un addon, utilise la commande `/wow-addon <description>` — elle coordonne automatiquement les agents dans le bon ordre.

| Agent | Usage |
|---|---|
| `wow-addon-architect` | Structure de projet, `.toc`, choix des libs |
| `wow-api-expert` | APIs Midnight, Secret Values, breaking changes vs TWW |
| `wow-lua-coder` | Écriture/refacto Lua avec patterns Midnight |
| `wow-ui-designer` | Frames, panels, tooltips, palette Think Twice |
| `wow-addon-debugger` | Diagnostic erreurs Lua / stack traces Midnight |

## Tests in-game

Pas de framework de test automatisé. Validation manuelle :
1. Activer **BugSack + BugGrabber** pour capturer les erreurs Lua
2. `/reload` après chaque changement de fichier
3. `/framestack` pour inspecter les frames sous le curseur
4. Tester hors combat ET en encounter (le système Secret Values change le comportement)
