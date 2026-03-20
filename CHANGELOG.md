# Changelog

Alle wichtigen Aenderungen an diesem Retail-12.x-Stand von MayronUI werden hier in komprimierter Form festgehalten.

## Aktueller Stand

### Repository und Struktur
- Repository auf einen sauberen MUI-Hauptstand fuer Retail 12.x umgestellt
- nur MUI und die wirklich benoetigten Begleit-AddOns in Git aufgenommen
- Fremd-AddOns wie `MoneyLooter`, `ZygorGuidesViewer`, `TradeSkillMaster`, `BugSack` und weitere Zusatzpakete bewusst ausgeschlossen
- deutsche `README.md` mit Funktions- und Strukturuebersicht hinzugefuegt

### MUI-Kern
- aktiven Kern auf die Menues `General`, `Action Bars`, `Unit Frames`, `Cast Bars`, `Chat` und `Minimap` ausgerichtet
- Konfigurationsstruktur in mehreren aktiven Bereichen an das modernisierte MUI-Muster angepasst
- deutsche Bezeichnungen und Menueeintraege an den aktuellen Stand angeglichen

### Chat
- Chat-Konfiguration neu geschnitten und an die uebrigen Menues angeglichen
- kaputte oder leere Unterstrukturen entfernt
- Eingabebox auf sinnvolle Kernoptionen reduziert
- verschiedene Chat-Button- und Layoutpfade stabilisiert
- mehrere Fehler bei Dropdowns, Lokalisierung und Konfigurationsrendering behoben

### Cast Bars
- Cast Bars wieder als aktiver Hauptbereich eingebunden
- Bezeichnung auf `Zauberleiste` / `Zauberleisten` vereinheitlicht
- allgemeine Moduloptionen erweitert
- individuelle Leisten um Ruecksetzen auf Standard ergaenzt
- mehrere Schutz- und Stabilitaetspfadfehler in den Laufzeitupdates behoben

### Unit Frames
- Namenleisten wiederhergestellt und sichtbarer gemacht
- `Unit Panels` in der Konfiguration auf `Unit Frames` umbenannt
- SUF-Bereich bewusst reduziert und auf sinnvolle MUI-Steuerung ausgerichtet
- Portrait-Verlauf und Portrait-Schalter ueberarbeitet

### Minimap
- problematische Altoptionen wie Form/Drehung entfernt
- Zonentext-Positionierung bereinigt
- Konfiguration auf klarere aktive Optionen reduziert
- mehrere Widget- und Positionspfade defensiver gemacht

### Installer und Setup
- Installer auf sauberen Neuinstallationspfad ausgerichtet
- Chat-Reset und Standardwerte im Installpfad gehaertet
- Begleit-AddOn-Profile fuer Setup und Layouts besser eingebunden

### Timer Bars
- Altmodul fuer Retail 12.x / Midnight technisch angehoben
- mehrere Taint-, Aura- und Eventfehler auf Retail entschärft
- Modul aktiviert, um die Modernisierung live weiterzufuehren
- weiterhin in aktiver Ueberarbeitung, noch nicht auf dem Reifegrad des restlichen modernisierten Kerns

## Hinweise

- Diese Datei ist bewusst kompakt gehalten und dokumentiert den groben Verlauf.
- Detailaenderungen bleiben weiterhin ueber die Git-Historie nachvollziehbar.
