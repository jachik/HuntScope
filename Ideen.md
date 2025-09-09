# App Beschreibung
Die App ist dafür gedacht, das Bild einer Wärmebildkamera optimal im Jagdkontext darzustellen. Hierfür kann das Display z.B. auf Rot/Schwarz geschaltet werden (rot ist für Wild nicht gut sichtbar).
Die App bringt folgende Funktionen mit:
- Erstellung von Fotos
- Aufnahme von Videos
- Automatisch Verbindungsaufnahme mit WBKs
- Custom-URL, falls Verbindung scheitert
- Darstellung auf iPad & iPhone
- Werbung für kostenlose Nutzung (taucht alle x Minuten auf)



TODOs:
- [X] Konfigurationsdialog etwas bequemer
- [] Lokalisierung
- [x] Links Balken entfernen im Konigurationsdialog
- [X] Logo erstellen
- [X] Splashscreen
- [] Hintergrund (=Logo?)
- Konfiguration URL
- Scan-Algorithmus
(- last-sleep kann auch 30 minuten betragn, wenn die app läuft und mal kurz in die Systemmeldungen reingeguckt wird )


TODO - vor Launch:
- Konfiguration RTSP (2 Std))
- Scanner RTSP (Vermutlich 1 Tag)
- RTSP-Viewer (vermutlich 1 Tag)
- WErbung (vermutlich 2-3 Std.)
- Abo (vermutlich 2-3 Std.)
- Lokalisierung (letzter Schritt ca. 2 Std.)
- Impressum?
- Hintergrundbild auch weiß


# Beschreibung Scanner

- beim Starten der App werden nur die letzten 5 Verbindungen rückwärts durchprobiert (oder evtl. gleicheztig gescannt,wenn ds schnell geht)
- sollte keine Verbindung zu Stande kommen, wird im Endeffekt ein Fehlericon angezeigt und der Bneutzer muss in die Konfiguratioon
- In der Konfiguration gibt es die Möglichkeit einen "Full-Connect" (oder wie man das nennen sollte, zu machen.
- Beim Full-connect werden alle passenden URLs durchprobiert (passend im Sinne zum Netzwerkwerk bassend)
- Als weiteres optionales Kriterium wird bei manchen Presets noch die SSID (bzw. ein Teil davon) gespeichert. Dies kann auch als zusätzlicher Fiter verwendet werden
Ist das so aus deiner Sicht sinnvoll? Wir hätte damit zwei Listen - eine lastknowngood-Liste und eine Preset-Liste. Zusätzlich gibt es noch die Möglichkeit eine Custom-URL einzugeben - diese wird der Preset-Liste einfach am Anfang hinzugefügt
