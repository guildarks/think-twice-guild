# Vault Architecture Decision

**Date:** 2026-05-05
**Status:** Accepted ✅
**Type:** Architecture/Structure

## Question
Comment organiser un système de knowledge management pour documenter le travail et les décisions?

## Options considérées

### Option A: Unique Journal File
- Une seule note "Journal" avec tout
- ❌ Devient trop grand et difficile à naviguer
- ❌ Difficile de retrouver des infos

### Option B: Folder-Based Organization ✅ CHOISIE
- 4 dossiers thématiques (Projects, Completed, Decisions, Patterns)
- Templates standardisés pour chaque type
- Index central pour naviguer
- ✅ Scalable et organisé
- ✅ Facile de retrouver des infos

### Option C: Tag-Based Only
- Utiliser uniquement les tags, pas de dossiers
- ❌ Confusion possible
- ❌ Moins intuitif

## Décision
**Folder-Based Organization** - Structure avec 4 dossiers + templates

### Structure Choisie
```
cerveaux claude/
├── Projects/          → Travaux en cours
├── Completed/         → Travaux terminés
├── Decisions/         → Choix architecturaux
├── Patterns/          → Conventions réutilisables
├── Bienvenue.md       → Index/Navigation
└── Templates          → Dans chaque dossier
```

## Conséquences

### Positives
- ✅ Clarté: On sait où chercher une info
- ✅ Scalabilité: Facile d'ajouter des notes
- ✅ Consistance: Templates standardisés
- ✅ Traçabilité: Historique complet du travail

### à Surveiller
- ⚠️ Garder les chemins de liaison à jour ([[links]])
- ⚠️ Nettoyer les notes terminées (archiver)
- ⚠️ Mettre à jour l'Index régulièrement

## Alternatives Futures
- Ajouter un dossier `Archive/` si trop de contenu
- Créer des vues graph pour visualiser les connexions
- Intégrer avec d'autres outils (Excalidraw, etc.)
