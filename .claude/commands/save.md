---
description: Sauvegarde la session courante dans .claude-memory/
---

Tu dois sauvegarder la conversation et le travail de la session actuelle dans la mémoire projet.

## Étapes

1. Récapitule ce qui a été fait dans la session : demandes de l'utilisateur, fichiers modifiés/créés, décisions prises, problèmes rencontrés et résolus
2. Crée un fichier dans `.claude-memory/` nommé `session-YYYY-MM-DD.md` (utilise la date du jour)
   - Si le fichier existe déjà pour aujourd'hui, ajoute une nouvelle section horodatée à la fin au lieu d'écraser
3. Structure le fichier avec :
   - **Date / heure**
   - **Résumé** (2-3 lignes)
   - **Actions effectuées** (liste à puces)
   - **Fichiers modifiés** (avec chemin)
   - **Décisions** (s'il y en a)
   - **À retenir** (notes importantes pour la prochaine session)
4. Reste concis : pas de paragraphes longs, des listes claires
5. Confirme à l'utilisateur le fichier créé/mis à jour et résume en une phrase ce qui a été sauvé

## Important

- Ne commit PAS automatiquement, laisse l'utilisateur décider
- Ne touche à aucun autre fichier que celui de la mémoire
