# Plan : Show Multiple Profiles in Popover

## Couche 1 — Structure générale

### Contexte

Aujourd'hui le popover affiche les stats d'**un seul profil** à la fois
(le profil actif, ou celui cliqué en mode multi-profil menu bar). Le
mode multi-profil existant concerne uniquement les **icônes de la menu
bar** — chaque profil a son bouton, mais cliquer sur l'un d'eux ouvre le
même popover mono-profil.

### Objectif

Ajouter un flag **"Show all profiles"** qui, lorsqu'activé, remplace le
dashboard mono-profil par un dashboard empilé affichant **tous les profils
sélectionnés** (`isSelectedForDisplay`) dans le même popover.

Stats affichées par profil :
- **Session usage** (fenêtre 5h)
- **All models weekly**
- **Sonnet daily** (si usage sonnet > 0)

Le profil **actif** (subscription en cours) est visuellement mis en avant.

### Architecture retenue

```
┌─────────────────────────────┐
│  SmartHeader (inchangé)     │
│  StatusBanners (inchangé)   │
├─────────────────────────────┤
│  ┌─ ProfileUsageCard ─────┐ │  ← profil actif, mis en avant
│  │  "Pro (Team)" [Active] │ │     (bordure accent, position haute)
│  │  Session:  ████░░ 68%  │ │
│  │  Weekly:   ██░░░░ 34%  │ │
│  │  Sonnet:   █░░░░░ 12%  │ │
│  └─────────────────────────┘ │
│  ┌─ ProfileUsageCard ─────┐ │  ← autres profils
│  │  "Personal"            │ │
│  │  Session:  ██░░░░ 40%  │ │
│  │  Weekly:   █░░░░░ 15%  │ │
│  └─────────────────────────┘ │
│  ...                        │
└─────────────────────────────┘
```

### Composants / modules touchés

| Module | Rôle dans le changement |
|--------|------------------------|
| **PopoverContentView** | Branchement conditionnel : mono-profil (existant) vs multi-profil (nouveau) |
| **MultiProfileDashboard** (nouveau) | Vue conteneur qui itère les profils sélectionnés et empile des `ProfileUsageCard` |
| **ProfileUsageCard** (nouveau) | Vue compacte par profil : header nom + badge "Active", puis 2-3 `UsageRow` condensées |
| **MultiProfileDisplayConfig** | Ajout du flag `showAllProfilesInPopover: Bool` |
| **ProfileStore** | Persistance du nouveau flag (déjà gérée par l'encodage Codable de la config) |
| **ManageProfilesView** | Toggle dans les settings multi-profil pour activer/désactiver le flag |

### Flux de données

Pas de nouveau fetch réseau — les profils sélectionnés ont déjà leur
`claudeUsage` persisté (rempli par `refreshAllSelectedProfiles()`).
Le `MultiProfileDashboard` lit directement
`profileManager.profiles.filter { $0.isSelectedForDisplay }` et leur
`.claudeUsage`.

### Risques architecturaux

1. **Hauteur du popover** — Avec 3+ profils, le popover peut devenir
   trop grand. Mitigation : `ScrollView` avec hauteur max, et vue
   compacte (pas de time markers / pace coloring en mode multi).

2. **Données stale** — Un profil sélectionné mais pas encore refreshé
   aura un `claudeUsage` vide ou périmé. Mitigation : afficher un
   indicateur "stale" si `lastUsedAt` est ancien.

3. **Interaction avec le mode mono-profil existant** — Le flag
   `showAllProfilesInPopover` n'est pertinent qu'en `displayMode == .multi`.
   En mode `.single`, on ignore le flag et on reste sur le comportement
   actuel.
