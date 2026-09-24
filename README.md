# EventDesk

Server-seitig gerenderte Rails-Anwendung zur Verwaltung von Konzerten mit begrenzter Kapazität
(Modul 223). Teilnehmer sehen veröffentlichte Konzerte und melden sich an, Organisatoren
verwalten Konzerte und Teilnehmerlisten, Administratoren zusätzlich Benutzer und Rollen.

Der zentrale Mehrbenutzerfall: melden sich zwei Personen gleichzeitig für den letzten freien
Platz an, entsteht genau eine Anmeldung.

## Technik

Ruby 4.0.6, Rails 8.1, SQLite, Pundit, Rails Authentication Generator, Rails-Testframework.
Code und Bezeichner sind englisch, die Oberfläche ist deutsch über `config/locales/de.yml`.

## Voraussetzungen

- Ruby 4.0.6 (siehe `.ruby-version`, z. B. über mise, rbenv oder asdf installiert)
- Bundler (wird mit Ruby geliefert)

SQLite wird über das `sqlite3`-Gem mitgeliefert. Ein `config/master.key` ist nicht nötig.

## Einrichten und starten

```bash
bin/setup --skip-server   # Gems installieren, Datenbank anlegen und mit Demodaten füllen
bin/dev                   # Anwendung auf http://localhost:3000
```

`bin/setup` legt die Entwicklungsdatenbank an und lädt dabei `db/seeds.rb`. Die Demodaten
lassen sich jederzeit mit `bin/setup --reset --skip-server` neu aufsetzen.

Bestätigungslinks für den E-Mail-Wechsel werden in der Entwicklung im Log ausgegeben.

Die Anwendung immer über `http://localhost:3000` öffnen, nicht über `127.0.0.1:3000`. Die
Bestätigungslinks zeigen auf `localhost`, und der Browser führt für beide Adressen getrennte
Anmeldungen. Wer sich unter `127.0.0.1` anmeldet und den Link öffnet, landet danach auf dem
Profil des Kontos, das unter `localhost` angemeldet ist, oder auf der Anmeldeseite. Die Adresse
wird trotzdem korrekt bestätigt.

## Demo-Konten

Alle Konten haben das Passwort `eventdesk2026!`.

| Rolle | E-Mail | Darf zusätzlich |
|---|---|---|
| Teilnehmer | `teilnehmer@eventdesk.test` | – (Konzerte ansehen, anmelden, stornieren, Profil) |
| Organisator | `organisator@eventdesk.test` | Konzerte verwalten, Teilnehmerlisten und Aktivitäten einsehen |
| Administrator | `admin@eventdesk.test` | wie Organisator, dazu Benutzer und Rollen verwalten |

Dazu kommen drei Konzerte der Organisatorin: ein Entwurf, ein veröffentlichtes Konzert mit zwei
Plätzen (zum Ausprobieren eines vollen Konzerts) und ein abgesagtes.

## Tests

```bash
bin/rails test                                  # gesamte Suite
bin/rails test test/models                      # nur ein Verzeichnis
bin/rails test test/models/concert_test.rb:158  # nur ein Test
```

Welche Anforderung wo geprüft wird, wie der Nebenläufigkeitstest aufgebaut ist und wie die
Mutationsprobe nachweist, dass der Kapazitätsschutz wirklich getestet ist: `docs/testing.md`.

## Weitere Dokumentation

Die Dokumentation liegt nicht im Repository, sondern im Abgabe-ZIP im Ordner `docs/`.
`script/package_submission` erstellt das Abgabepaket mit diesem Ordner.

| Datei | Inhalt |
|---|---|
| `docs/spec/PROJECT.md` | Fachliche Grundlagen, Rollen, Konventionen |
| `docs/datenmodell.md` | Datentypen, Constraints, Nebenläufigkeit, ER-Diagramm |
| `docs/testing.md` | Testkonzept, Abdeckung, manuelle Prüfliste |
| `docs/abgabe-stand.md` | Erreichter Stand, offene Punkte, Abweichungen vom Antrag, Prüfergebnisse |
| `docs/spec/` | Aufgaben 1–8 mit Spezifikation und Checkliste |
