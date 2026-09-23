# EventDesk

Server-seitig gerenderte Rails-Anwendung zur Verwaltung von Konzerten mit begrenzter Kapazität
(Modul 223). Teilnehmer sehen veröffentlichte Konzerte und melden sich an, Organisatoren
verwalten Konzerte und Teilnehmerlisten, Administratoren zusätzlich Benutzer und Rollen.

Der zentrale Mehrbenutzerfall: melden sich zwei Personen gleichzeitig für den letzten freien
Platz an, entsteht genau eine Anmeldung.

## Technik

Ruby 4.0.6, Rails 8.1, SQLite, Pundit, Rails Authentication Generator, Rails-Testframework.
Code und Bezeichner sind englisch, die Oberfläche ist deutsch über `config/locales/de.yml`.

## Einrichten und starten

```bash
bin/setup          # Abhängigkeiten und Datenbank
bin/dev            # Anwendung auf http://localhost:3000
```

Bestätigungslinks für den E-Mail-Wechsel werden in der Entwicklung im Log ausgegeben.

## Tests

```bash
bin/rails test                                  # gesamte Suite
bin/rails test test/models                      # nur ein Verzeichnis
bin/rails test test/models/concert_test.rb:158  # nur ein Test
```

Welche Anforderung wo geprüft wird, wie der Nebenläufigkeitstest aufgebaut ist und wie die
Mutationsprobe nachweist, dass der Kapazitätsschutz wirklich getestet ist: `docs/testing.md`.

## Weitere Dokumentation

| Datei | Inhalt |
|---|---|
| `docs/spec/PROJECT.md` | Fachliche Grundlagen, Rollen, Konventionen |
| `docs/datenmodell.md` | Datentypen, Constraints, Nebenläufigkeit, ER-Diagramm |
| `docs/testing.md` | Testkonzept, Abdeckung, manuelle Prüfliste |
| `docs/spec/` | Aufgaben 1–8 mit Spezifikation und Checkliste |
