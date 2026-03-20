# Mui-Retail-12.x

Dieses Repository enthält den aktuellen Retail-Stand von MayronUI fuer WoW 12.x inklusive der AddOns, die fuer das MUI-Setup und die integrierten Profile direkt benoetigt werden.

## Funktionen

### Aktiver MUI-Kern
- `General`
- `Action Bars`
- `Unit Frames`
- `Cast Bars`
- `Chat`
- `Minimap`
- `Timer Bars` in laufender Modernisierung fuer Retail 12.x / Midnight

### Bereits modernisierte Bereiche
- ueberarbeitete Konfiguration mit klarerer Menuestruktur
- stabilisierter Installer und Profil-Reset
- moderne Font-Verwaltung fuer den aktiven MUI-Bestand
- bereinigte Minimap-Optionen
- modernisierte Chat-Konfiguration
- fest integrierte Castbar-/UnitFrame-/ActionBar-Pfade

### Externe Integrationen
- `Bartender4` fuer Aktionsleisten und Profilimporte
- `Masque` fuer Button-Skins
- `ShadowedUnitFrames` fuer Unit-Frame-Profile und MUI-Anbindung
- `Grid2` fuer Heiler-Layouts und Profilimporte
- `!KalielsTracker` als eingebundene Begleitkomponente
- `Leatrix_Plus` fuer verknuepfte Schnellzugriffe im UI

## Enthaltene AddOns

### MUI-Kern
- `MUI_Core`
- `MUI_Config`
- `MUI_Setup`

### Zugehoerige Begleit-AddOns
- `Bartender4`
- `Grid2`
- `Grid2Options`
- `Grid2LDB`
- `Masque`
- `ShadowedUnitFrames`
- `ShadowedUF_Options`
- `!KalielsTracker`
- `Leatrix_Plus`

Diese AddOns sind im Repository, weil MayronUI dafuer Presets, Integrationen, Schnellzugriffe oder Setup-Importe besitzt.

## Bewusst nicht enthalten

Die folgenden AddOns gehoeren nicht zum offiziellen MUI-Stand dieses Repositories und werden bewusst nicht mit versioniert:

- `MoneyLooter`
- `ZygorGuidesViewer`
- `TradeSkillMaster`
- `TradeSkillMaster_AppHelper`
- `BetterBuffBars`
- `BugSack`
- `!BugGrabber`
- zusaetzliche `Masque`-Skinpacks
- persoenliche Ordner wie `WTF`, Cache-Dateien oder sonstige lokale Daten

## Ziel dieses Repositories

Dieses Repository soll einen sauberen, reproduzierbaren MUI-Stand fuer Retail 12.x abbilden:

- mit modernisiertem MUI-Kern
- mit den dazugehoerigen Pflicht- und Begleit-AddOns
- ohne unnoetigen Fremd-Bestand
- ohne persoenliche WoW-Daten

## Installation

1. Repository herunterladen oder klonen.
2. Die enthaltenen AddOn-Ordner in den WoW-Retail-Ordner `Interface/AddOns` legen.
3. WoW starten oder `/reload` ausfuehren.
4. Falls noetig, das MUI-Setup mit `/mui i` erneut ausfuehren.

## Hinweis zur Struktur

Auch wenn im lokalen `AddOns`-Ordner weitere AddOns vorhanden sein koennen, werden in Git nur die oben genannten MUI-relevanten Ordner gepflegt.

## Aenderungen und Verlauf

Wichtige Aenderungen werden in der Datei [`CHANGELOG.md`](/D:/World%20of%20Warcraft/_retail_/Interface/AddOns/CHANGELOG.md) gepflegt.

Dort stehen:
- groessere Modernisierungen
- Struktur- und Konfigurationsaenderungen
- Aktivierungen neuer oder ueberarbeiteter Module
- wichtige Stabilitaets- und Fehlerkorrekturen

## Status

Aktiver Fokus dieses Standes:

- stabilisierter MUI-Kern
- modernisierte Konfiguration
- laufende Anpassung einzelner Altmodule an Retail 12.x / Midnight
