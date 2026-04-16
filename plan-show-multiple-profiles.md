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

---

## Couche 2 — Impacts détaillés

### 2.1 MultiProfileDisplayConfig — Ajout du flag

**Fichier :** `Claude Usage/Shared/Models/MenuBarIconConfig.swift` (l.286-351)

**Propriété ajoutée :**
```swift
var showAllProfilesInPopover: Bool  // default: false
```

**Impacts :**
- Ajouter la propriété après `showActiveProfileIndicator` (l.295)
- Ajouter le paramètre avec default `false` dans `init(...)` (l.297-317)
- Ajouter la clé dans l'enum `CodingKeys` (l.321-331)
- Ajouter le décodage avec fallback `false` dans `init(from:)` (l.333-346)
  pour la migration des utilisateurs existants

**Pas d'impact sur `ProfileStore`** — la config entière est déjà sérialisée
via Codable. Le fallback dans `init(from:)` couvre la compatibilité.

### 2.2 ManageProfilesView — Toggle settings

**Fichier :** `Claude Usage/Views/Settings/App/ManageProfilesView.swift`

**Insertion après le toggle `showActiveProfileIndicator`** (l.243-255),
avant le message info (l.258).

**Pattern identique aux autres toggles :**
```swift
SettingToggle(
    title: "Show All Profiles in Popover",
    description: "Display usage for all selected profiles...",
    isOn: Binding(
        get: { profileManager.multiProfileConfig.showAllProfilesInPopover },
        set: { newValue in
            var config = profileManager.multiProfileConfig
            config.showAllProfilesInPopover = newValue
            profileManager.updateMultiProfileConfig(config)
            NotificationCenter.default.post(name: .displayModeChanged, object: nil)
        }
    )
)
```

### 2.3 PopoverContentView — Branchement conditionnel

**Fichier :** `Claude Usage/MenuBar/PopoverContentView.swift`

**Zone impactée :** l.144-198 (entre les banners et le closing VStack)

**Logique de branchement :**
```
if displayMode == .multi && showAllProfilesInPopover
  → MultiProfileDashboard(...)     // NOUVEAU
else
  → viewing tag existant (l.144-188)
  → SmartUsageDashboard existant (l.191)
  → ContextualInsights existant (l.193-198)
```

Le branchement remplace **à la fois** le viewing tag (qui n'a plus de
sens quand tous les profils sont visibles) et le SmartUsageDashboard.

Les `ContextualInsights` ne sont PAS affichées en mode all-profiles
(trop de bruit — un seul insight par profil n'est pas actionnable).

**La largeur du popover reste à 280pt** (l.202). Les `ProfileUsageCard`
sont conçues pour ce gabarit.

### 2.4 MultiProfileDashboard — Vue conteneur (nouveau)

**Fichier :** `Claude Usage/MenuBar/PopoverContentView.swift`
(ajout dans le même fichier, dans la section MARK existante)

**Interface :**
```swift
struct MultiProfileDashboard: View {
    let profiles: [Profile]          // filtrés isSelectedForDisplay
    let activeProfileId: UUID?
```

**Comportement :**
- Trie les profils : actif en premier, puis par nom
- Wrappé dans `ScrollView` avec `.frame(maxHeight: 400)` pour 3+ profils
- Itère et affiche un `ProfileUsageCard` par profil
- Séparateur léger (`PopoverDivider`) entre chaque card

**Source de données :**
```swift
profileManager.profiles.filter { $0.isSelectedForDisplay }
```

Chaque profil expose `profile.claudeUsage ?? .empty` — pas de risque
de nil puisque `ClaudeUsage.empty` existe déjà.

### 2.5 ProfileUsageCard — Vue compacte par profil (nouveau)

**Fichier :** `Claude Usage/MenuBar/PopoverContentView.swift`

**Interface :**
```swift
struct ProfileUsageCard: View {
    let profile: Profile
    let isActive: Bool
    let usage: ClaudeUsage
```

**Layout :**
1. **Header** : initiales avatar (réutilise `profileInitials(for:)`) +
   nom + badge "Active" (capsule accent) si `isActive`
2. **Session usage** : `UsageRow` simplifié —
   `showTimeMarker: false`, `showPaceMarker: false`, `isPeakHighlighted: false`
3. **All models weekly** : `UsageRow` simplifié — sans tag "WEEKLY"
4. **Sonnet weekly** : `UsageRow` conditionnel si `usage.sonnetWeeklyTokensUsed > 0`

**Mise en avant du profil actif :**
- Bordure gauche accent (3pt, `Color.accentColor`)
- Background légèrement plus opaque (`.opacity(0.06)` vs `.opacity(0.03)`)

**Compacité vs SmartUsageDashboard :**
La `ProfileUsageCard` ne montre PAS :
- Opus weekly (trop rare pour un aperçu multi-profil)
- API Usage card (credits/costs — reste accessible via le popover mono-profil)
- Time markers / pace coloring (simplifié)
- Peak hours highlighting
- Reset time text (seulement la barre de progression + pourcentage)

### 2.6 Localisation

**Fichier :** `Localizable.strings` (ou `.xcstrings`)

Nouvelles clés :
- `settings.multi_profile.show_all_in_popover` — titre du toggle
- `settings.multi_profile.show_all_in_popover.description` — description

Pas de nouvelles clés pour les `UsageRow` — on réutilise les clés
existantes (`menubar.session_usage`, `menubar.all_models`, `menubar.sonnet_usage`).
