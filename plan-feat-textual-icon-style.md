# Plan — Icon Style "Textual" (`textual`)

## Couche 1 — Structure générale

### Objectif

Ajouter un 6ème style d'icône (`textual`) en mode single-profile et un 5ème (`textual`) en mode multi-profile.
Ce style affiche dans la menu bar un **texte compact** :

```
● S 23% 3h 12m
```

Avec combinaison session + week quand "show week usage" est actif :

```
● S 23% 3h12m | ● W 88% 2d 23m
```

### A — Modèle de données (enums + configs)

Deux enums à étendre :

| Enum | Fichier | Ajout |
|------|---------|-------|
| `MenuBarIconStyle` | `DataStore.swift` | case `.textual` |
| `MultiProfileIconStyle` | `MenuBarIconConfig.swift` | case `.textual` |

Chaque enum reçoit un nouveau cas avec `displayName`, `description` (et `shortNameKey` / `icon` pour le multi-profile).

Pas de nouvelles propriétés de configuration — les settings existants (`showTimeMarker`, `usePaceColoring`, `showRemainingPercentage`, `showWeek`, `showProfileLabel`) couvrent tous les comportements demandés.

### B — Rendu (MenuBarIconRenderer)

Deux nouvelles méthodes de rendu dans `MenuBarIconRenderer.swift` :

1. **`createTextualStyle()`** — single-profile : génère un `NSImage` contenant le texte attributé (pastille + lettre + pourcentage + durée restante).
2. **`createMultiProfileTextual()`** — multi-profile : même logique, adapté au contexte multi-profil (session | week côte à côte si `showWeek` actif).

La méthode `createImage()` (routeur principal, ligne ~16) reçoit un nouveau `case .textual` qui dispatch vers `createTextualStyle()`.
Idem dans `StatusBarUIManager` pour le multi-profile.

### C — Settings UI

| Mode | Vue | Changement |
|------|-----|------------|
| Single-profile | `IconStylePicker.swift` | Le nouveau style apparaît dans la grille (6ème carte) |
| Multi-profile | `ManageProfilesView.swift` | Le picker segmenté affiche un 5ème segment |

**Comportement spécifique multi-profile** : quand le style `textual` est sélectionné, le toggle "Show Profile Label" est désactivé / masqué (le label est déjà intégré dans le texte via la lettre S/W).

### D — Logique métier de formatage

Nouvelle fonction utilitaire pour formater la durée restante avant reset :
- Calcule le temps restant (session: window 5h, week: 7 jours)
- Affiche `Xd Yh Zm` en omettant les composantes à zéro
- Exemples : `2h` (pas `0d 2h 0m`), `1d 3h` (pas `1d 3h 0m`)

Le pourcentage affiché respecte `showRemainingPercentage` :
- Activé → pourcentage restant (77% si 23% consommé)
- Désactivé → pourcentage consommé (23%)

### E — Flux de données

Aucun nouveau flux : le style `textual` consomme les mêmes données que les styles existants (`ClaudeUsage`, `PaceStatus`, configs). Il ne fait que les projeter différemment (texte vs graphique).

### Risques architecturaux

| Risque | Impact | Mitigation |
|--------|--------|------------|
| **Largeur variable du texte** dans la menu bar | Le texte peut être long (~25 chars avec session+week), risque de tronquage sur petits écrans | Tester sur résolution minimale ; potentiellement raccourcir le format en mode multi-profile (ex: omettre les minutes si > 1j) |
| **Compatibilité `NSImage` texte** | Les autres styles génèrent des images bitmap ; le texte doit rester net en Retina | Utiliser `NSAttributedString` dessiné dans un `NSImage` à la bonne échelle, comme `createPercentageOnlyStyle()` le fait déjà |
| **Sérialisation** | Ajouter un cas enum ne casse pas le `Codable` existant tant qu'on ne change pas les `rawValue` | Le nouveau cas `textual` s'ajoute sans modifier les existants ; fallback au style par défaut si un ancien client lit la config |
