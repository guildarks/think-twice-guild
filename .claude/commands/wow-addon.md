---
description: Crée un addon WoW Think Twice de bout en bout, en demandant d'abord où placer la doc dans Obsidian.
---

Tu vas créer un addon WoW pour la guilde **Think Twice** (Midnight 12.0.5) à partir de cette demande :

**$ARGUMENTS**

IMPORTANT : tu exécutes ce workflow dans la conversation PRINCIPALE. Tu DOIS donc
t'arrêter et attendre les réponses de l'utilisateur aux moments indiqués. Ne lance
JAMAIS toute la chaîne d'un coup.

---

## ÉTAPE 0 — Demander l'emplacement Obsidian (BLOQUANT, EN PREMIER)

Avant d'écrire le moindre code :

1. Via MCP obsidian (`vault_list`), lis l'arborescence du dossier `wow/` et de ses
   sous-dossiers (notamment `wow/Addons/`).
2. Détermine le nom de l'addon depuis la demande (préfixe `TTG_`).
3. Pose la question à l'utilisateur avec l'outil **AskUserQuestion**, en proposant :
   - les sous-dossiers existants de `wow/Addons/` comme options,
   - une option "Racine de wow/Addons/",
   - une option "Créer une nouvelle catégorie".
4. Si l'utilisateur choisit "Créer une nouvelle catégorie", demande-lui le nom
   (via AskUserQuestion ou en texte) puis confirme le chemin final.
5. **ARRÊTE-TOI et attends la réponse.** Ne continue pas tant que l'emplacement
   n'est pas choisi et confirmé.

Mémorise le chemin final, par ex. `wow/Addons/Combat/TTG_Alert.md`.

---

## ÉTAPE 1 à 5 — Création de l'addon (via sous-agents)

Une fois l'emplacement confirmé, enchaîne les sous-agents :

1. **wow-addon-architect** → structure (.toc, libs, arborescence)
2. **wow-api-expert** → validation APIs Midnight / Secret Values
3. **wow-lua-coder** → implémentation Lua dans `C:\Users\kevin\Desktop\claude\<NomAddon>\`
4. **wow-ui-designer** → frames / palette Think Twice (seulement si UI nécessaire)
5. **wow-addon-debugger** → diagnostic et correction (seulement si erreurs)

Respecte les règles Midnight : préfixe `TTG_`, Interface `120005`, `issecretvalue()`
sur les données de combat, pas de `COMBAT_LOG_EVENT_UNFILTERED`, APIs `C_*`.

---

## ÉTAPE 6 — Documentation (via sous-agent, chemin imposé)

Délègue à **wow-addon-documenter** en lui passant EXPLICITEMENT le chemin confirmé
à l'étape 0. Exemple de brief :

> Documente l'addon <NomAddon>. Emplacement imposé : `wow/Addons/Combat/<NomAddon>.md`.
> UNE seule note tout-en-un : doc + code source complet de TOUS les fichiers embarqué.
> PAS de note _index, PAS de [[wiki-links]] — un addon = un seul point dans le graph.

---

## ÉTAPE 7 — Mémoire collective (via sous-agent)

Délègue à **wow-memory-keeper** : nom de l'addon, agents utilisés, résumé des
problèmes/solutions/patterns. Il consolide dans `wow/AgentMemory/`.

---

## Fin
Affiche un résumé : fichiers créés, emplacement de la doc Obsidian, patterns
mémorisés, et la commande de test en-game (`/reload`).
