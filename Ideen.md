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
- [x] Links Balken entfernen im Konigurationsdialog
- [X] Logo erstellen
- [X] Splashscreen
- [x] Hintergrund (=Logo?)
- [X] Konfigurationsdialog etwas bequemer
- [] Uhrzeit, Temeperatur und Windgeschwindigkeit
- [] Mondphase und Zeiten
- [] Test aktuelle Version von VLC mit deaktivieren Boradcast-Einstellungen

TODO - vor Launch:
10.09.
- [x] Probleme mit Splash bei kurzer Abwesenheit
- [x] Hintergrundbild-Overlay mit Symbol für keine VErbindung als (als flush)
- [X] Konfigurationsdialog RTSP (2 Std))
- [x] RTSP-Scanner (Vermutlich 1 Tag)
11.09.
- [x] RTSP-Viewer (vermutlich 1 Tag)
- [x] Videos aufnehmen
- [x] Aunahmebutton soll blinken
- [x] Fotos erstellen
- [x] custom-URL prüfen
- [x] Impressum & Datenschutz
- [x] Eigene Werbung (erstmal ein Dialog)
- [x] eigene Werbung auch hin und wieder per Zufall (damit der Benutzer das effektiv wahrnimmt)
- [] Eigenen Werbespot erstellen
- [] RTSP-Streams sammeln (Apps laden und zerpflücken)
- [x] Datenschutzerklärung Text größer

12.09.
- App-Beschreibung einfügen
- Screenshots App
13.09.
- [] Abo (vermutlich 2-3 Std.)
- [x] Lokalisierung (letzter Schritt ca. 2 Std.)
14.09.
- [x] Keine Verbindung zum Ad-Store -> eigene Werbung für die App
- [] Datenschutzvereinbarung prüfen 1 Std. 
- [] Endlokalisierung 0,5 Std. 
- [] kostenlosen Monat anbieten
- [] Haptik beim Klicken
15.09. 
->>>>> Launch
Optional, wenn noch Zeit ist:
- [] Uhrzeit, Temeperatur und Windgeschwindigkeit
- [] Mondphase und Zeiten
- [] Videostream nicht beenden, wenn Werbung angezeigt wird
- [] Der CountDown, wann WErbung angezegit wird, beginnt mit dem Anzeigen - nicht mit dem Schließen - d.h. es kann sein, dass WErbung mehrfach hintereinander gezeigt wird
- [] Versionsnumer der App und des bilds in die Konfiguration übernehmen, um prüfen zu können, dass eine neue Version installiert wurde

Erledigt:
- [x] WErbung (vermutlich 2-3 Std.)
- [x] Hintergrundbild auch weiß
- [x] Konfigurationsdialog Kreise
- [x] Konfigurationsdialog durchsichtig


# Wärmebildhersteller:
- [] PUlsar
- [] Liemke
- [] Hikvision
- [] Burris
- [] Leica
- [] INfriray
- [] Guide Sensmart
- [] ATN
- [] Steiner
- [] Nighthog
- [] Themtec

# Beschreibung Scanner

- beim Starten der App werden nur die letzten 5 Verbindungen rückwärts durchprobiert (oder evtl. gleicheztig gescannt,wenn ds schnell geht)
- sollte keine Verbindung zu Stande kommen, wird im Endeffekt ein Fehlericon angezeigt und der Bneutzer muss in die Konfiguratioon
- In der Konfiguration gibt es die Möglichkeit einen "Full-Connect" (oder wie man das nennen sollte, zu machen.
- Beim Full-connect werden alle passenden URLs durchprobiert (passend im Sinne zum Netzwerkwerk bassend)
- Als weiteres optionales Kriterium wird bei manchen Presets noch die SSID (bzw. ein Teil davon) gespeichert. Dies kann auch als zusätzlicher Fiter verwendet werden
Ist das so aus deiner Sicht sinnvoll? Wir hätte damit zwei Listen - eine lastknowngood-Liste und eine Preset-Liste. Zusätzlich gibt es noch die Möglichkeit eine Custom-URL einzugeben - diese wird der Preset-Liste einfach am Anfang hinzugefügt



ich hätte gerne einen neuen Konfiguratinsdialog "RTSPStreamConfig" (seperat in einer neuen Datei), der aufgerufen wird, wenn man auf "Kamerakonfiguration" in der Hauptkonfiguration klickt. Die HauptKonfiguration geht zu und der neue Dialog geht auf - im gleichen Style und Größe wie der aktuelle Konfiguraionsdialog. Oben rechts auch ein Symbol zu schließen - genau wie im Konfigurationsdialog. Auch die Farbwahl bleibt berücksichtigt (d.h. rot oder weiß=. 
Dieser neue Konfigurationsdialog hat einen Button "Auto-Connect" und alternativ dazu ein Feld mit "Benutzerdefinierte URL" und einen Button Test dahinter. Aufbau: 
- ÜBerfschrift "Stream-Konfiguration", daneben rechts in der Ecke das Symbol zum schließen (wie in ConfigDialogVioe)
- 1. Zeile Button mit Auto-Connect
- 2. Zeile Kleine Überschrift für den nächsten Abschnitt "Benutzerdefinierte URL"
- 3. Zeile Textfeld mit Button rechts daneben "Test""

{
  "version": 2,
  "presets": [
    /* Sytong Outdoor */
    "rtsp://192.168.1.1:554/h264/channel=0/video/",
    "rtsp://192.168.1.254/xxx.mov",
    "rtsp://192.168.3.15:554/h264/channel=0/video/",
    /* Zeiss */
    "rtsp://192.168.11.220/1/h264major",
    /* Burris Thermal Handheld v2 */
    "rtsp://192.168.42.1/preview",
    /* testing */
    "rtsp://192.168.100.154:8554/thermal"
  ]
}
	
Die nächste Aufgabe auf der Todo-Liste ist: Snapshots
Bitte implementiere die Möglichkeit, snapshosts zu machen. Diese sollen in der Fotobibliothek abgelegt werden (sind dafür irgendwelche Rechte notwendig?). D.h. wenn der User auf de Snapshot-Button drück, landet ein Bild in der Fotobibliothek. 

WEnn ich die Konfiguration verlasse, wird kurz das Fehlersymbol eingeblendet und auch die Wassermarke. Diese sollte doch gar nicht mehr erscheinen. wie kann das sein?


Ich habe die Verbindung zur Kamera testweise beendet und es wurde wieder das Wasserzeichen im Hintergrund angezeigt. Bitte prüfe den Code, warum das Wasserzeichen immer noch angezeigt wird. 


KI-Prompts
ich nehme einen weißen Hintergrund, weil das grelle Licht natürlich stört und ich will ja zum Kaufen animieren. Kannst du mir ein Bild in Full-HD erstellen, auf dem ein zeichentrick Hirsch mit einer Krone und einer Brille dargestellt ist und einer Sprechblase mit "Erlebe alle Funktionen ohne Unterbrechen und hole dir jetzt HuntScop Premium"
