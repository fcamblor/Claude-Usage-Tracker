# Plan — Icon Style "Textual" (`textual`)

## Couche 1 — Structure générale

### Objectif

Ajouter un 6ème style d'icône (`textual`) en mode single-profile et un 5ème (`textual`) en mode multi-profile.
Ce style affiche dans la menu bar un **texte compact** :

```
● S 23% 3h 12m
```

### Architecture des modes (clarification)

**Single-profile** : session et week sont des métriques **séparées** (`MetricIconConfig`), chacune avec son propre `iconStyle` et son propre `NSStatusItem`. Avec le style textual, chaque métrique produit un item indépendant :
- Session activée → `● S 23% 3h12m`
- Week activée → `● W 88% 2d 23m`
- Les deux activées → deux items séparés dans la menu bar

**Multi-profile** : un seul item par profil. Le flag `showWeek` contrôle si session et week sont combinés dans le même item :
- `showWeek` désactivé → `● S 23% 3h12m`
- `showWeek` activé → `● S 23% 3h12m | ● W 88% 2d 23m`

Ce sont deux axes indépendants : multi-profile = plusieurs profils affichés ensemble ; showWeek = afficher la weekly en plus de la session pour un même profil.

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
Idem dans `StatusBarUIManager.updateMultiProfileButtons()` pour le multi-profile.

### C — Settings UI

| Mode | Vue | Changement |
|------|-----|------------|
| Single-profile | `IconStylePicker.swift` | Le nouveau style apparaît dans la grille (6ème carte) |
| Multi-profile | `ManageProfilesView.swift` | Le picker segmenté affiche un 5ème segment |

**Comportement spécifique multi-profile** : quand le style `textual` est sélectionné, le toggle "Show Profile Label" est **désactivé** (disabled, pas masqué) — cohérent avec la convention de l'app qui désactive les champs incompatibles plutôt que de les cacher. La lettre S/W dans le texte rend ce label redondant.

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
| **Largeur variable du texte** dans la menu bar | Le texte peut être long (~25 chars avec session+week en multi-profile), risque de tronquage sur petits écrans | Tester sur résolution minimale ; potentiellement raccourcir le format (ex: omettre les minutes si > 1j) |
| **Compatibilité `NSImage` texte** | Les autres styles génèrent des images bitmap ; le texte doit rester net en Retina | Utiliser `NSAttributedString` dessiné dans un `NSImage` à la bonne échelle, comme `createPercentageOnlyStyle()` le fait déjà |
| **Sérialisation** | Ajouter un cas enum ne casse pas le `Codable` existant tant qu'on ne change pas les `rawValue` | Le nouveau cas `textual` s'ajoute sans modifier les existants ; fallback au style par défaut si un ancien client lit la config |

---

## Couche 2 — Impacts détaillés

### A — Modèle de données

#### A.1 — `MenuBarIconStyle` (single-profile)
**Fichier** : `Claude Usage/Shared/Storage/DataStore.swift` (lignes 4-40)

- Ajouter `case textual` dans l'enum `MenuBarIconStyle`
- Ajouter dans `displayName` : `return "Textual"` (ou `"Text"`)
- Ajouter dans `description` : `return "Colored dot with letter, percentage, and time remaining"`

**Impact UI** : `IconStylePicker` itère `MenuBarIconStyle.allCases` via `ForEach` — le nouveau cas apparaît automatiquement. La formule de largeur des cartes passe de `/ 5` à `/ 6`.

#### A.2 — `MultiProfileIconStyle` (multi-profile)
**Fichier** : `Claude Usage/Shared/Models/MenuBarIconConfig.swift` (lignes 225-283)

- Ajouter `case textual` dans l'enum `MultiProfileIconStyle`
- `displayName` : `"Textual"`
- `shortNameKey` : `"multiprofile.style_textual"`
- `description` : `"Colored dot, letter, percentage and time remaining"`
- `icon` : `"textformat"` (SF Symbol)

**Impact UI** : `ManageProfilesView` itère `MultiProfileIconStyle.allCases` dans un `Picker(.segmented)` — le nouveau cas apparaît automatiquement comme 5ème segment.

#### A.3 — Aucune modification des structs de config
Les structs `MetricIconConfig`, `MenuBarIconConfiguration` et `MultiProfileDisplayConfig` restent inchangées. Le style textual exploite :
- `showRemainingPercentage` (bool, existe dans les deux configs)
- `showTimeMarker` (bool, existe dans les deux configs)
- `usePaceColoring` / `showPaceMarker` (bools, existent dans les deux configs)
- `showWeek` (bool, `MultiProfileDisplayConfig` uniquement — pertinent multi-profile seulement)
- `showProfileLabel` (bool, `MultiProfileDisplayConfig` — sera disabled quand `textual` sélectionné)

### B — Rendu

#### B.1 — `createTextualStyle()` (single-profile)
**Fichier** : `Claude Usage/MenuBar/MenuBarIconRenderer.swift`

**Signature** (alignée sur les méthodes existantes, ex: `createPercentageOnlyStyle` lignes 473-521) :
```swift
private func createTextualStyle(
    metricType: MenuBarMetricType,
    metricData: MetricData,
    isDarkMode: Bool,
    colorMode: MenuBarColorMode,
    singleColorHex: String,
    showIconName: Bool,           // non utilisé directement (la lettre S/W est toujours affichée)
    usage: ClaudeUsage,
    showTimeMarker: Bool,
    paceStatus: PaceStatus?,
    showPaceMarker: Bool
) -> NSImage
```

**Composition du texte attributé** (de gauche à droite) :
1. **Pastille colorée** `●` — couleur pace si `showPaceMarker && paceStatus != nil`, sinon couleur status via `getColorForMode()`. Si `usePaceColoring` désactivé et `showPaceMarker` désactivé → pastille grise (`.secondaryLabelColor`)
2. **Espace** + **Lettre** `S` ou `W` — couleur foreground (blanc/noir selon dark mode), déterminée par `metricType`
3. **Espace** + **Pourcentage** `23%` — `metricData.displayText` (déjà calculé avec `showRemainingPercentage`)
4. **Espace** + **Durée restante** `3h 12m` — calculée via nouvelle helper `formatTimeRemaining()`, affiché seulement si `showTimeMarker == true`

**Technique de rendu** : `NSAttributedString` dessiné dans `NSImage`, même pattern que `createPercentageOnlyStyle()` (lignes 494-508). Font: `NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)`.

**Dispatch** : ajouter `case .textual:` dans le `switch config.iconStyle` de `createImage()` (ligne 77). Ce cas a besoin du paramètre `usage` (pour calculer le temps restant) et de `globalConfig.showTimeMarker` — l'objet `usage` est déjà passé à certains styles (battery, progressBar) donc pas de changement de signature.

#### B.2 — `createMultiProfileTextual()` (multi-profile)
**Fichier** : `Claude Usage/MenuBar/MenuBarIconRenderer.swift`

**Signature** (alignée sur `createMultiProfilePercentage` lignes 1230-1315) :
```swift
func createMultiProfileTextual(
    sessionPercentage: Double,
    weekPercentage: Double?,          // nil si showWeek == false
    sessionStatus: UsageStatusLevel,
    weekStatus: UsageStatusLevel,
    profileName: String?,             // inutilisé pour textual mais gardé pour cohérence d'interface
    monochromeMode: Bool,
    isDarkMode: Bool,
    useSystemColor: Bool,
    usage: ClaudeUsage,               // NOUVEAU param vs les autres multi-profile renderers
    showTimeMarker: Bool,             // NOUVEAU
    sessionPaceStatus: PaceStatus?,
    weekPaceStatus: PaceStatus?,
    showPaceMarker: Bool
) -> NSImage
```

**Composition** :
- Segment session : `● S {sessionPercentage}% {timeRemaining}` (durée optionnelle si `showTimeMarker`)
- Si `weekPercentage != nil` : séparateur ` | ` + segment week `● W {weekPercentage}% {timeRemaining}`
- Pas de label profil sous le texte (le label est intégré via S/W)

**Note** : Les paramètres `usage` et `showTimeMarker` sont nouveaux par rapport aux méthodes multi-profile existantes. C'est le seul cas où on a besoin des dates de reset dans un renderer multi-profile.

#### B.3 — Fonction helper `formatTimeRemaining()`
**Fichier** : `Claude Usage/MenuBar/MenuBarIconRenderer.swift` (section MARK: - Helper Methods)

```swift
private func formatTimeRemaining(resetTime: Date?, duration: TimeInterval) -> String?
```

- Calcule `timeRemaining = resetTime - now` (si `resetTime` est dans le futur)
- Convertit en jours/heures/minutes
- Omet les composantes à zéro : `2d 3h` (pas `2d 3h 0m`), `45m` (pas `0d 0h 45m`)
- Retourne `nil` si `resetTime` est nil ou dans le passé

Le `resetTime` et `duration` sont obtenus via `usage.sessionResetTime` / `usage.weeklyResetTime` et `Constants.sessionWindow` / `Constants.weeklyWindow`, comme le fait déjà `calculateTimeMarkerFraction()` (lignes 1391-1416).

### C — Settings UI

#### C.1 — `IconStylePicker.swift` (single-profile)
**Fichier** : `Claude Usage/Views/Settings/Components/IconStylePicker.swift`

**Changements** :
- Ligne 16 : formule largeur `/ 5` → `/ 6` (6 cartes)
- Ajouter un `case .textual:` dans `IconPreviewLarge` (lignes 82-135) pour la preview. Affichage preview : texte `● S 60%` en vert + gris, taille réduite pour tenir dans la carte (~50pt de large)
- Hauteur du picker (ligne 30) : potentiellement augmenter si le texte est trop tassé, sinon garder `80`

#### C.2 — `ManageProfilesView.swift` (multi-profile)
**Fichier** : `Claude Usage/Views/Settings/App/ManageProfilesView.swift`

**Changements** :
- Le `Picker(.segmented)` (lignes 119-133) itère `MultiProfileIconStyle.allCases` → le 5ème segment apparaît automatiquement
- **Disable du toggle "Show Profile Label"** (lignes 152-165) : ajouter un `.disabled()` conditionnel quand `profileManager.multiProfileConfig.iconStyle == .textual`. Le toggle reste visible mais grisé, avec un tooltip ou une indication que le style textual inclut déjà le label.

#### C.3 — Localisation
**Fichier(s)** : `Localizable.strings` (ou équivalent)

Clés à ajouter :
- `"multiprofile.style_textual"` → `"Text"` (label court pour le segment picker)

### D — StatusBarUIManager (dispatch multi-profile)

**Fichier** : `Claude Usage/MenuBar/StatusBarUIManager.swift`

#### D.1 — `updateMultiProfileButtons()` (lignes 305-466)
Ajouter `case .textual:` dans le `switch config.iconStyle` (ligne 379). Ce cas appelle `renderer.createMultiProfileTextual(...)`.

**Différence vs les autres cas** : il faut passer l'objet `usage` (`profile.claudeUsage ?? ClaudeUsage.empty`) et `config.showTimeMarker` au renderer. Les autres styles n'ont pas besoin de `usage` directement car ils ne calculent pas le temps restant en texte — ils utilisent `timeMarkerFraction` (un `CGFloat`). Le style textual a besoin de la `Date` brute pour formater `3h 12m`.

#### D.2 — `updateAllButtons()` / `updateButton()` (lignes 509-598)
Pas de changement nécessaire : ces méthodes appellent `renderer.createImage()` qui dispatche déjà via le `switch` de la section B.1. Il faudra juste s'assurer que `usage` est bien passé (il l'est déjà pour battery/progressBar).

### E — Résumé des fichiers impactés

| Fichier | Nature du changement |
|---------|---------------------|
| `DataStore.swift` | +1 case enum, +2 propriétés computed |
| `MenuBarIconConfig.swift` | +1 case enum, +4 propriétés computed |
| `MenuBarIconRenderer.swift` | +1 méthode single (`createTextualStyle`), +1 méthode multi (`createMultiProfileTextual`), +1 helper (`formatTimeRemaining`), +1 case dans `createImage()` switch |
| `StatusBarUIManager.swift` | +1 case dans `updateMultiProfileButtons()` switch |
| `IconStylePicker.swift` | formule largeur /5→/6, +1 case preview |
| `ManageProfilesView.swift` | +`.disabled()` sur toggle "Show Profile Label" |
| `Localizable.strings` | +1 clé |
