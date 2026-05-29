# Graph Report - .  (2026-05-29)

## Corpus Check
- Corpus is ~647 words - fits in a single context window. You may not need a graph.

## Summary
- 54 nodes · 63 edges · 11 communities (10 shown, 1 thin omitted)
- Extraction: 63% EXTRACTED · 37% INFERRED · 0% AMBIGUOUS · INFERRED: 23 edges (avg confidence: 0.81)
- Token cost: 18,883 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Regles Midnight & Secret Values|Regles Midnight & Secret Values]]
- [[_COMMUNITY_APIs renommees & Agents code|APIs renommees & Agents code]]
- [[_COMMUNITY_Workspace GUILDARKS & Permissions|Workspace GUILDARKS & Permissions]]
- [[_COMMUNITY_Evenements (remplacement CLEU)|Evenements (remplacement CLEU)]]
- [[_COMMUNITY_Palette graphique Think Twice|Palette graphique Think Twice]]
- [[_COMMUNITY_Addon TTG_Hello|Addon TTG_Hello]]
- [[_COMMUNITY_Comms restreintes|Comms restreintes]]
- [[_COMMUNITY_Structure d'addon|Structure d'addon]]
- [[_COMMUNITY_Permissions settings.local|Permissions settings.local]]

## God Nodes (most connected - your core abstractions)
1. `Secret Values Protection` - 7 edges
2. `COMBAT_LOG_EVENT_UNFILTERED (removed)` - 6 edges
3. `Renamed APIs Rule` - 6 edges
4. `WoW Midnight 12.0.5` - 5 edges
5. `Think Twice Color Palette` - 5 edges
6. `midnight-audit audit.py Permission` - 4 edges
7. `TTG_WelcomeMsg Addon` - 4 edges
8. `Restricted Comms Rule` - 4 edges
9. `TTG_Hello.lua Implementation` - 4 edges

## Surprising Connections (you probably didn't know these)
- `midnight-audit audit.py Permission` --conceptually_related_to--> `COMBAT_LOG_EVENT_UNFILTERED (removed)`  [INFERRED]
  .claude/settings.local.json → CLAUDE.md
- `midnight-audit audit.py Permission` --conceptually_related_to--> `Secret Values Protection`  [INFERRED]
  .claude/settings.local.json → CLAUDE.md
- `TTG_WelcomeMsg Addon` --conceptually_related_to--> `TTG_ Prefix Convention`  [INFERRED]
  .claude/settings.local.json → CLAUDE.md
- `TTG_WelcomeMsg Addon` --conceptually_related_to--> `GUILDARKS Addon Workspace`  [INFERRED]
  .claude/settings.local.json → CLAUDE.md
- `TTG_Hello.lua Implementation` --implements--> `TTG_Hello Addon`  [INFERRED]
  TTG_Hello/TTG_Hello.lua → TTG_Hello/TTG_Hello.toc

## Hyperedges (group relationships)
- **Midnight 12.0 Critical Compliance Rules** — claudemd_secret_values, claudemd_cleu_removed, claudemd_restricted_comms, claudemd_incombatlockdown, claudemd_renamed_apis [EXTRACTED 1.00]
- **Encounter Lifecycle Event Flow** — claudemd_encounter_start, claudemd_encounter_end, claudemd_unit_health_event, claudemd_unit_aura_event [INFERRED 0.75]
- **wow-* Specialized Agent Pipeline** — claudemd_agent_architect, claudemd_agent_api_expert, claudemd_agent_lua_coder, claudemd_agent_ui_designer, claudemd_agent_debugger [EXTRACTED 1.00]

## Communities (11 total, 1 thin omitted)

### Community 0 - "Regles Midnight & Secret Values"
Cohesion: 0.28
Nodes (9): wow-addon-debugger, BugSack + BugGrabber, InCombatLockdown(), In-Game Manual Testing, Interface 120005 (.toc), issecretvalue(), WoW Midnight 12.0.5, Secret Values Protection (+1 more)

### Community 1 - "APIs renommees & Agents code"
Cohesion: 0.22
Nodes (8): wow-api-expert, wow-lua-coder, C_Container.GetContainerItemInfo, C_Item.GetItemInfo, C_Spell.GetSpellInfo, C_UnitAuras.GetAuraDataByIndex, Lua 5.1 Constraints (+1 more)

### Community 2 - "Workspace GUILDARKS & Permissions"
Cohesion: 0.38
Nodes (7): Think Twice Guild (Hyjal-FR), TTG_ Prefix Convention, GUILDARKS Addon Workspace, midnight-audit audit.py Permission, Obsidian MCP Permissions, Local Settings Permissions, TTG_WelcomeMsg Addon

### Community 3 - "Evenements (remplacement CLEU)"
Cohesion: 0.33
Nodes (6): COMBAT_LOG_EVENT_UNFILTERED (removed), CLEU Removal Rule, ENCOUNTER_END event, ENCOUNTER_START event, UNIT_AURA event, UNIT_HEALTH event

### Community 4 - "Palette graphique Think Twice"
Cohesion: 0.40
Nodes (5): ACCENT (#A78BFA), wow-ui-designer, BG_DARK (#0A0A0F), Think Twice Color Palette, PINK (#F472B6)

### Community 5 - "Addon TTG_Hello"
Cohesion: 0.60
Nodes (5): TTG_Hello Addon, Event-Driven Frame Listener Pattern, TTG_Hello.lua Implementation, PLAYER_LOGIN Event Handler, TTG_Hello.toc Manifest

### Community 6 - "Comms restreintes"
Cohesion: 0.83
Nodes (4): AceComm, IsCommRestricted(), Restricted Comms Rule, SendAddonMessage

### Community 7 - "Structure d'addon"
Cohesion: 0.67
Nodes (4): AceAddon Layout (Ace3/LibStub), Recommended Addon Structure, wow-addon-architect, .toc Manifest

## .toc Branding — RÈGLE IMPORTANTE
Tous les fichiers `.toc` de ce workspace utilisent :
- `## Title: GUILDARKS — |cffA78BFa<NomAddon>|r`
- `## Author: GUILDARKS`
Ne jamais utiliser "Think Twice" comme Author ou Title dans un `.toc`.

## Knowledge Gaps
- **13 isolated node(s):** `allow`, `Obsidian MCP Permissions`, `UNIT_HEALTH event`, `UNIT_AURA event`, `ENCOUNTER_START event` (+8 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `midnight-audit audit.py Permission` connect `Workspace GUILDARKS & Permissions` to `Regles Midnight & Secret Values`, `Evenements (remplacement CLEU)`?**
  _High betweenness centrality (0.279) - this node is a cross-community bridge._
- **Why does `Secret Values Protection` connect `Regles Midnight & Secret Values` to `APIs renommees & Agents code`, `Workspace GUILDARKS & Permissions`?**
  _High betweenness centrality (0.278) - this node is a cross-community bridge._
- **Why does `COMBAT_LOG_EVENT_UNFILTERED (removed)` connect `Evenements (remplacement CLEU)` to `Workspace GUILDARKS & Permissions`?**
  _High betweenness centrality (0.241) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `Secret Values Protection` (e.g. with `wow-api-expert` and `InCombatLockdown()`) actually correct?**
  _`Secret Values Protection` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Renamed APIs Rule` (e.g. with `wow-api-expert` and `WoW Midnight 12.0.5`) actually correct?**
  _`Renamed APIs Rule` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `WoW Midnight 12.0.5` (e.g. with `InCombatLockdown()` and `Renamed APIs Rule`) actually correct?**
  _`WoW Midnight 12.0.5` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Think Twice Color Palette` (e.g. with `wow-ui-designer` and `Think Twice Guild (Hyjal-FR)`) actually correct?**
  _`Think Twice Color Palette` has 2 INFERRED edges - model-reasoned connections that need verification._
