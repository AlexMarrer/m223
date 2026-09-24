# EventDesk – Stand bei der Abgabe

Stand: 24.09.2026. Grundlage ist die Projektdokumentation Version 1.6 in `docs/dokumentation.md`.

---

## 1. Erreichter Stand

Umgesetzt sind alle funktionalen Anforderungen F01–F10 und alle Qualitätsanforderungen Q01–Q05:

- Registrierung, Login und Logout, Profil, Passwortwechsel mit aktuellem Passwort und
  E-Mail-Wechsel mit Bestätigungslink im Entwicklungslog
- Konzertliste und Konzertdetails mit Setlist und optionalem Playlist-Link
- Anmeldung und Stornierung, auch unter gleichzeitigen Zugriffen auf den letzten Platz
- Konzertverwaltung für Organisatoren und Admins: erstellen, bearbeiten, Entwürfe löschen,
  veröffentlichen und absagen, mit Konfliktmeldung bei veralteter Version
- Teilnehmerliste und Aktivitätsfeed für Organisatoren und Admins
- Benutzerverwaltung nur für Admins, die eigene Rolle bleibt gesperrt
- Berechtigungen serverseitig mit Pundit, Aktivitäten in derselben Transaktion wie die
  fachliche Änderung

---

## 2. Offen

- Sichtprüfung im Browser, `docs/testing.md` Abschnitt 7.2. Die Abläufe über HTTP
  (Abschnitt 7.1) sind geprüft.
- Die Dokumentation (Projektantrag 1.6) liegt als `docs/dokumentation.md` vor, aber noch nicht
  als PDF. Die Präsentation fehlt noch. Ohne beide PDFs kann das Abgabe-ZIP nicht erstellt
  werden.

---

## 3. Abweichungen vom Antrag

| Antrag 1.5 | Umsetzung | Grund |
|---|---|---|
| Entität `Event`, Fremdschlüssel `event_id` | `Concert`, `concert_id` | Domänenspezifischer Fachbegriff, siehe Änderungsliste Abschnitt 2 |
| Rollentabelle: nur Admins verwalten Konzerte | Organisatoren und Admins verwalten Konzerte | F05, Breadboards und Wireframes verlangen es |
| Abschnitt 1 und S12/S13: Organisatoren verwalten Benutzer | Nur Admins verwalten Benutzer | F08 und Abschnitt 3 verlangen es |
| `USER` ohne Feld für die neue E-Mail-Adresse | Zusätzliches Feld `unconfirmed_email` | Die Bestätigung braucht einen Ort für die ausstehende Adresse |
| Pflichtfelder offen | Beschreibung und Setlist sind ab dem Veröffentlichen Pflicht | Entwürfe dürfen unvollständig sein, veröffentlichte Konzerte nicht |
| S09 als eigene Seite „Konzertverwaltung" | Die Konzertliste zeigt Organisatoren und Admins alle Konzerte mit Entwürfen und dem Link „Neues Konzert" | Eine zweite Liste mit fast gleichem Inhalt hätte keinen Mehrwert |
| „Zurück"-Links auf S05, S06, S09, S12 und S14 | Feste Navigation oben auf jeder Seite | Jeder Bereich ist von überall mit einem Klick erreichbar |
| Anmelden und Stornieren führen zu S05 bzw. zur aktualisierten Liste | Beide führen zur Konzertdetailseite S04 mit Bestätigung | Die Meldung erscheint dort, wo sich freie Plätze und Status ändern |
| Neue E-Mail-Adresse direkt in S06 und S13 | Eigenes Formular bzw. eigene Schaltfläche „Bestätigungslink senden" | Namensänderung und E-Mail-Wechsel werden getrennt gespeichert und bestätigt |
| S10: Entwurf speichern oder veröffentlichen | S10 speichert nur. Veröffentlicht wird auf S04 | Veröffentlichen ist ein eigener, protokollierter Schritt |
| Keine Angabe zu Sitzungen | Technische Tabelle `sessions` des Rails-Authentication-Generators | Vom Antrag als technische Ergänzung vorgesehen |

---

## 4. Durchgeführte Prüfungen

Alle Prüfungen am 23.09.2026 lokal ausgeführt (Ruby 4.0.6, Linux).

| Prüfung | Ergebnis |
|---|---|
| `bin/rails test` | 253 Tests, 807 Assertions, 0 Fehler |
| `bin/rails test` aus dem entpackten Code-ZIP ohne `config/master.key` | 253 Tests, 0 Fehler |
| `bin/brakeman`, `bin/bundler-audit`, `bin/importmap audit`, `bin/rubocop` | ohne Befund |
| `bundle install` im Frozen-Modus wie in der CI | erfolgreich |
| Fehlerprobe: Kapazitätsprüfung `elsif full?` entfernt (Stand mit 250 Tests) | 5 von 250 Tests scheitern, darunter `ConcertTest#test_rejects_a_registration_for_a_full_concert` und beide Nebenläufigkeitstests. Nach dem Zurücksetzen wieder 0 Fehler |
| README in frischer Kopie: `bin/setup --skip-server`, `bin/dev` | Datenbank und Demodaten angelegt. Login mit allen drei Demo-Konten gelingt, nur der Admin erreicht die Benutzerverwaltung |
| Abläufe über HTTP, `docs/testing.md` Abschnitt 7.1 | Punkte 1–18 erfüllt, darunter E-Mail-Bestätigung, Buchung, Stornierung und Bearbeitungskonflikt |
| Sichtprüfung im Browser, `docs/testing.md` Abschnitt 7.2 | nicht durchgeführt |
| `script/package_submission` | Code-ZIP mit README, 25 Testdateien und `docs/` samt Bild und PDF erstellt, ohne `config/master.key`, Datenbanken und Logs |

Die GitHub-CI läuft erfolgreich durch, zuletzt Lauf #20 am 24.09.2026 für Commit
`2b44d64` mit allen Jobs (`scan_ruby`, `scan_js`, `lint`, `test`). Nicht ausgeführt: die
Sichtprüfung im Browser.

### Korrektur der CI

Alle Jobs scheiterten bei „Set up Ruby" mit Bundler-Exitcode 16 (`ProductionError`). In
`Gemfile.lock` fehlte die Prüfsumme für `pundit`. Im Frozen-Modus der CI darf Bundler sie nicht
nachtragen. Die Prüfsumme wurde mit `bundle lock` ergänzt.

Danach wären drei weitere Jobs gescheitert. Sie sind ebenfalls behoben:

- `bundler-audit`: `json` 2.11.2 hat die Lücke CVE-2026-54696. Neu gilt `~> 2.19, >= 2.19.9`.
  Unter 3.0 bleibt es, weil `json` 3 das Lesen signierter Nachrichten in Rails bricht.
- `brakeman`: Die Warnung zum Playlist-Link ist in `config/brakeman.ignore` begründet. Das Model
  lässt nur Adressen mit `http://` oder `https://` zu.
- `system-test`: Das Projekt hat keine Systemtests, der Job ist entfernt.

### Buchung abgesagter oder begonnener Konzerte

Eine direkte Buchungs- oder Stornierungsanfrage für ein abgesagtes oder begonnenes Konzert wird
weiterhin von `RegistrationPolicy` abgewiesen. Die Meldung nennt jetzt den Grund: „Dieses Konzert
wurde abgesagt." bzw. „Dieses Konzert hat bereits begonnen." Ein Entwurf erhält weiterhin die
allgemeine Berechtigungsmeldung, damit seine Existenz verborgen bleibt. Drei Tests prüfen die
neuen Meldungen und scheitern ohne die Änderung.

### Passwortwechsel

Fehlte `password_challenge` in der Anfrage oder war es `nil`, prüfte `has_secure_password` das
aktuelle Passwort nicht. `PasswordsController` wandelt den Wert jetzt immer in einen String um,
so läuft die Prüfung in jedem Fall. Zwei neue Tests decken das fehlende Feld und `nil` ab. Ohne
die Korrektur scheitern beide.

---

## 5. Abgabepaket

```bash
script/package_submission pfad/zur/Dokumentation.pdf pfad/zur/Praesentation.pdf
```

Das Skript legt in `tmp/abgabe/` zuerst `eventdesk-code.zip` an. Es enthält alle Dateien, die
Git nicht ignoriert, und zusätzlich den ganzen Ordner `docs/`. Dessen Unterordner wie
`docs/spec/` stehen in `.gitignore`, ein `git archive` würde sie deshalb auslassen. Nur wenn
beide PDFs vorhanden sind, entsteht danach `eventdesk-abgabe.zip` mit den zwei PDFs und dem Code-ZIP. Sonst nennt das Skript die
fehlenden Dateien.

Kontrolle:

- [ ] Dokumentation als PDF (Projektantrag 1.6): **fehlt noch**
- [ ] Präsentation als PDF: **fehlt noch**
- [x] Code-ZIP mit README, `test/` und `docs/` samt Bildern: mit dem Skript geprüft
