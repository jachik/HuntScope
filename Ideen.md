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
- [x] Hintergrund (=Logo?)
- Konfiguration URL
- Scan-Algorithmus


TODO - vor Launch:
10.09.
- Hintergrundbild-Overlay mit Symbol für keine VErbindung als (als flush)
- Konfiguration RTSP (2 Std))
- Scanner RTSP (Vermutlich 1 Tag)
11.09.
- RTSP-Streams sammeln (Apps laden und zerflücken)
12.09.
- RTSP-Viewer (vermutlich 1 Tag)
- Abo (vermutlich 2-3 Std.)
- Lokalisierung (letzter Schritt ca. 2 Std.)
- Homepage: Datenschutz + Impressum 
- [x] WErbung (vermutlich 2-3 Std.)
- [x] Hintergrundbild auch weiß
- [x] Konfigurationsdialog Kreise
- [] Konfigurationsdialog durchsichtig


# Beschreibung Scanner

- beim Starten der App werden nur die letzten 5 Verbindungen rückwärts durchprobiert (oder evtl. gleicheztig gescannt,wenn ds schnell geht)
- sollte keine Verbindung zu Stande kommen, wird im Endeffekt ein Fehlericon angezeigt und der Bneutzer muss in die Konfiguratioon
- In der Konfiguration gibt es die Möglichkeit einen "Full-Connect" (oder wie man das nennen sollte, zu machen.
- Beim Full-connect werden alle passenden URLs durchprobiert (passend im Sinne zum Netzwerkwerk bassend)
- Als weiteres optionales Kriterium wird bei manchen Presets noch die SSID (bzw. ein Teil davon) gespeichert. Dies kann auch als zusätzlicher Fiter verwendet werden
Ist das so aus deiner Sicht sinnvoll? Wir hätte damit zwei Listen - eine lastknowngood-Liste und eine Preset-Liste. Zusätzlich gibt es noch die Möglichkeit eine Custom-URL einzugeben - diese wird der Preset-Liste einfach am Anfang hinzugefügt



ich hätte gerne einen neuen Konfiguratinsdialog "RTSPStreamConfig" (seperat in einer neuen Datei), der aufgerufen wird, wenn man auf "Kamerakonfiguration" in der Hauptkonfiguration klickt. Der HauptKonfiguration geht zu und der neue Dialog geht auf - im gleichen Style und Größe wie der aktuelle Konfiguraionsdialog. Auch die Farbwahl bleibt berücksichtigt (d.h. rot oder weiß=. 
Dieser neue Konfigurationsdialog hat einen Button "Auto-Connect" und alternativ dazu ein Feld mit "Benutzerdefinierte URL" und einen Button Test dahinter. Geschlossen wird der Dialog wieder über den bereits vorhandenen Button, mit dem man auch in die Konfiguraion kommt. 
