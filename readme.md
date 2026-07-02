# Readme

Das Problem mit GitHub (YAML): GitHub Actions bietet zwar einen eigenen schedule-Auslöser (Cron) in der .yml-Datei an, dieser ist aber in der Praxis extrem unzuverlässig. GitHub gibt in seiner Dokumentation offiziell an, dass geplante Aufgaben nur ausgeführt werden, wenn gerade Serverkapazitäten frei sind. Wenn zur vollen Stunde Millionen von Nutzern weltweit ihre Skripte starten, reiht GitHub dein Skript ganz hinten ein. Aus 09:00 Uhr wird dann oft 09:25 Uhr oder 09:45 Uhr – oder der Lauf fällt bei extremer Überlastung sogar komplett aus.

Die Lösung mit cron-job.org: cron-job.org fungiert als kompromissloser, externer Wecker. Der Dienst ruft pünktlich auf die Sekunde die GitHub-Schnittstelle (API) von außen auf. Diesen externen Anstoß haben wir in der YAML-Datei als repository_dispatch definiert. Solche direkten API-Befehle von außen behandelt GitHub als "Live-Events" mit höchster Priorität, wodurch dein Skript sofort und ohne Warteschleife gestartet wird.
