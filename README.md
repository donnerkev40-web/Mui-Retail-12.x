# Mui-Retail-12.x

Dieses Repository enthält den aktuellen Retail-Stand von MayronUI für WoW 12.x inklusive der AddOns, die für das MUI-Setup und die integrierten Profile direkt benötigt werden.

## Funktionen

### Aktiver MUI-Kern
- `General`
- `Action Bars`
- `Unit Frames`
- `Cast Bars`
- `Chat`
- `Minimap`
- `Timer Bars` in laufender Modernisierung für Retail 12.x / Midnight

### Bereits modernisierte Bereiche
- überarbeitete Konfiguration mit klarerer Menüstruktur
- stabilisierter Installer und Profil-Reset
- moderne Font-Verwaltung für den aktiven MUI-Bestand
- bereinigte Minimap-Optionen
- modernisierte Chat-Konfiguration
- fest integrierte Castbar-/UnitFrame-/ActionBar-Pfade

### Externe Integrationen
- `Bartender4` für Aktionsleisten und Profilimporte
- `Masque` für Button-Skins
- `ShadowedUnitFrames` für Unit-Frame-Profile und MUI-Anbindung
- `Grid2` für Heiler-Layouts und Profilimporte
- `!KalielsTracker` als eingebundene Begleitkomponente
- `Leatrix_Plus` für verknüpfte Schnellzugriffe im UI

## Enthaltene AddOns

### MUI-Kern
- `MUI_Core`
- `MUI_Config`
- `MUI_Setup`

### Zugehörige Begleit-AddOns
- `Bartender4`
- `Grid2`
- `Grid2Options`
- `Grid2LDB`
- `Masque`
- `ShadowedUnitFrames`
- `ShadowedUF_Options`
- `!KalielsTracker`
- `Leatrix_Plus`

Diese AddOns sind im Repository, weil MayronUI dafür Presets, Integrationen, Schnellzugriffe oder Setup-Importe besitzt.

## Ziel dieses Repositories

Dieses Repository soll einen sauberen, reproduzierbaren MUI-Stand für Retail 12.x abbilden:

- mit modernisiertem MUI-Kern
- mit den dazugehörigen Pflicht- und Begleit-AddOns
- mit klar definiertem Repository-Umfang

## Installation

1. Repository herunterladen oder klonen.
2. Die enthaltenen AddOn-Ordner in den WoW-Retail-Ordner `Interface/AddOns` legen.
3. WoW starten oder `/reload` ausführen.
4. Falls nötig, das MUI-Setup mit `/mui i` erneut ausführen.

## Hinweis zur Struktur

Auch wenn im lokalen `AddOns`-Ordner weitere AddOns vorhanden sein können, werden in Git nur die oben genannten MUI-relevanten Ordner gepflegt.

## Änderungen und Verlauf

Wichtige Änderungen werden in der Datei [`CHANGELOG.md`](/D:/World%20of%20Warcraft/_retail_/Interface/AddOns/CHANGELOG.md) gepflegt.

Dort stehen:
- größere Modernisierungen
- Struktur- und Konfigurationsänderungen
- Aktivierungen neuer oder überarbeiteter Module
- wichtige Stabilitäts- und Fehlerkorrekturen

## Status

Aktiver Fokus dieses Standes:

- stabilisierter MUI-Kern
- modernisierte Konfiguration
- laufende Anpassung einzelner Altmodule an Retail 12.x / Midnight
