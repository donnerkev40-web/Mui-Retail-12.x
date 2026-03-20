# Changelog

Alle wichtigen Änderungen an diesem Retail-12.x-Stand von MayronUI werden hier in komprimierter Form festgehalten.

## Aktueller Stand

### Repository und Struktur
- Repository auf einen sauberen MUI-Hauptstand für Retail 12.x umgestellt
- nur MUI und die wirklich benötigten Begleit-AddOns in Git aufgenommen
- deutsche `README.md` mit Funktions- und Strukturübersicht hinzugefügt

### MUI-Kern
- aktiven Kern auf die Menüs `General`, `Action Bars`, `Unit Frames`, `Cast Bars`, `Chat` und `Minimap` ausgerichtet
- Konfigurationsstruktur in mehreren aktiven Bereichen an das modernisierte MUI-Muster angepasst
- deutsche Bezeichnungen und Menüeinträge an den aktuellen Stand angeglichen

### Chat
- Chat-Konfiguration neu geschnitten und an die übrigen Menüs angeglichen
- kaputte oder leere Unterstrukturen entfernt
- Eingabebox auf sinnvolle Kernoptionen reduziert
- verschiedene Chat-Button- und Layoutpfade stabilisiert
- mehrere Fehler bei Dropdowns, Lokalisierung und Konfigurationsrendering behoben

### Cast Bars
- Cast Bars wieder als aktiver Hauptbereich eingebunden
- Bezeichnung auf `Zauberleiste` / `Zauberleisten` vereinheitlicht
- allgemeine Moduloptionen erweitert
- individuelle Leisten um Rücksetzen auf Standard ergänzt
- mehrere Schutz- und Stabilitätspfadfehler in den Laufzeitupdates behoben

### Unit Frames
- Namenleisten wiederhergestellt und sichtbarer gemacht
- `Unit Panels` in der Konfiguration auf `Unit Frames` umbenannt
- SUF-Bereich bewusst reduziert und auf sinnvolle MUI-Steuerung ausgerichtet
- Portrait-Verlauf und Portrait-Schalter überarbeitet

### Minimap
- problematische Altoptionen wie Form/Drehung entfernt
- Zonentext-Positionierung bereinigt
- Konfiguration auf klarere aktive Optionen reduziert
- mehrere Widget- und Positionspfade defensiver gemacht

### Installer und Setup
- Installer auf sauberen Neuinstallationspfad ausgerichtet
- Chat-Reset und Standardwerte im Installpfad gehärtet
- Begleit-AddOn-Profile für Setup und Layouts besser eingebunden

### Timer Bars
- Altmodul für Retail 12.x / Midnight technisch angehoben
- mehrere Taint-, Aura- und Eventfehler auf Retail entschärft
- Modul aktiviert, um die Modernisierung live weiterzuführen
- weiterhin in aktiver Überarbeitung, noch nicht auf dem Reifegrad des restlichen modernisierten Kerns

## Hinweise

- Diese Datei ist bewusst kompakt gehalten und dokumentiert den groben Verlauf.
- Detailänderungen bleiben weiterhin über die Git-Historie nachvollziehbar.
