# EventDesk – Testkonzept

Kurzfassung für die Abnahme: wie die Tests laufen, welche Anforderung wo geprüft wird und
womit belegt ist, dass die Tests nicht bloss mitlaufen.

Fachlich massgebend bleiben `docs/EventDesk_Projektuebersicht.md` (Aufgabe 8) und
`docs/spec/PROJECT.md`. Technische Details zum Datenmodell: `docs/datenmodell.md`.

---

## 1. Tests ausführen

```bash
bin/rails test                                  # gesamte Suite
bin/rails test test/models                      # nur ein Verzeichnis
bin/rails test test/models/concert_test.rb      # nur eine Datei
bin/rails test test/models/concert_test.rb:158  # nur ein Test
```

Es braucht keine Vorbereitung: Rails lädt das Testschema aus `db/schema.rb`, die Testdaten
kommen aus `test/fixtures/users.yml`.

Stand der letzten Ausführung (23.09.2026): **253 Tests, 807 Assertions, 0 Fehler.**

Die Suite läuft parallel über alle Prozessorkerne. Tritt ein Fehler nur sporadisch auf, hilft
`PARALLEL_WORKERS=1 bin/rails test` beim Eingrenzen.

---

## 2. Aufbau

| Verzeichnis | Inhalt |
|---|---|
| `test/models/` | Validierungen, Beziehungen, Buchungs- und Statusregeln, Aktivitätsprotokoll, Nebenläufigkeit |
| `test/controllers/` | echte Requests inklusive Authentisierung, Autorisierung und Formularfehlern |
| `test/policies/` | Pundit-Policies als Objekte, ergänzend zu den Requests |
| `test/mailers/` | Bestätigungsmail beim E-Mail-Wechsel |
| `test/test_helper.rb` | `concert_attributes` und `published_concert_attributes` als minimale gültige Konzertdaten |
| `test/test_helpers/session_test_helper.rb` | `sign_in_as` und `sign_out` |

Zwei Punkte sind bewusst gesetzt:

- **Berechtigungen werden als Request geprüft**, nicht nur über die Oberfläche. Dass ein Knopf
  fehlt, ist kein Schutz — die Tests schicken den Request trotzdem ab.
- **`config.i18n.raise_on_missing_translations = true`** in `config/environments/test.rb`. Damit
  prüft jeder View-Test nebenbei die Konvention aus `PROJECT.md`: deutscher Text steht in
  `config/locales/de.yml` und nirgends sonst.

---

## 3. Abdeckung der Anforderungen

Gegliedert wie `docs/EventDesk_Projektuebersicht.md`, Aufgabe 8.

| Anforderung | Geprüft in |
|---|---|
| Validierungen, Beziehungen, eindeutige Anmeldung | `models/concert_test.rb`, `user_test.rb`, `registration_test.rb`, `activity_test.rb` |
| Gültiger Login, ungültiger Login, Zugriff ohne Session | `controllers/sessions_controller_test.rb`; jeder Controller-Test prüft zusätzlich die Weiterleitung ohne Session |
| Erlaubte und verweigerte Requests, fremde Daten, Rollen | `policies/*_test.rb` und die Verweigerungstests in `controllers/` |
| Gültige Anmeldung, doppelte Anmeldung, volles Konzert | `models/concert_test.rb`, `controllers/registrations_controller_test.rb` |
| Abgesagtes und begonnenes Konzert | `models/concert_test.rb`, `controllers/registrations_controller_test.rb` |
| Stornierung und erneute Anmeldung danach | `models/registration_test.rb`, `controllers/registrations_controller_test.rb` |
| Parallelität, letzter freier Platz | `models/concert_concurrency_test.rb` |
| Transaktionen, Rollback | `models/activity_logging_test.rb` |
| Konzertstatus: nur Entwürfe löschbar, Absage vor Beginn, Anmeldungen bleiben | `models/concert_test.rb`, `controllers/concerts_controller_test.rb`, `controllers/concerts/publications_controller_test.rb`, `controllers/concerts/cancellations_controller_test.rb` |
| Optimistic Locking | `models/concert_test.rb`, `controllers/concerts_controller_test.rb` |

---

## 4. Nebenläufigkeit

`test/models/concert_concurrency_test.rb` bildet zwei gleichzeitige Buchungsversuche auf den
letzten Platz nach. Drei Dinge sind dafür nötig, sonst prüft der Test nichts:

1. **`self.use_transactional_tests = false`.** Sonst hielte die Testtransaktion die
   Schreibsperre und der zweite Versuch wartete auf etwas, das nie committet.
2. **Eine eigene Datenbankverbindung je Thread** über `connection_pool.with_connection`, wie
   bei zwei echten Requests. Eine gemeinsame Verbindung würde die Versuche nacheinander
   ausführen.
3. **Ein Zeitfenster zwischen Lesen und Schreiben.** Ein Abonnent auf `sql.active_record`
   verzögert jede Belegungszählung, damit beide Versuche lesen, bevor einer schreibt. Ohne das
   liefen die Transaktionen ohnehin hintereinander — und der Test bliebe auch ohne Schutz grün.

Geschützt wird die Stelle durch `Concert#protected_by_transaction`: SQLite öffnet die
Transaktion als `BEGIN IMMEDIATE`, Status und Belegung werden darin und ungecacht gelesen.
Siehe `docs/datenmodell.md`, Abschnitt 6.

---

## 5. Transaktionsklammern

Die fünf Paare aus `docs/datenmodell.md`, Abschnitt 7, haben je einen Rollback-Test in
`models/activity_logging_test.rb`: Anmeldung, Stornierung, Veröffentlichung, Änderung eines
veröffentlichten Konzerts, Absage.

Der Test ersetzt die Aktivitäten *eines* Konzertobjekts durch eine Sammlung, die beim Speichern
`ActiveRecord::RecordInvalid` wirft. Geprüft wird anschliessend immer **beides**: dass keine
Aktivität geschrieben wurde *und* dass die fachliche Änderung zurückgerollt ist. Nur die
Aktivität zu prüfen, würde ein fehlendes Rollback nicht bemerken.

---

## 6. Mutationsprobe

Nachweis, dass die Tests den Schutz wirklich prüfen. Die Mutation wird von Hand eingebaut, die
Suite ausgeführt und die Änderung sofort wieder verworfen — **sie wird nie committet.**

### Probe A: Schutz der Kapazitätsprüfung entfernen

In `app/models/concert.rb` `protected_by_transaction` auf den ungeschützten Kern reduzieren:

```ruby
def protected_by_transaction
  reload
  yield
end
```

Ergebnis: **5 Fehler von 248 Tests** (geprüft vor den zwei neuen Passworttests, seither nicht wiederholt).

- beide Tests in `ConcertConcurrencyTest` — das Konzert wird überbucht
- die Rollback-Tests für Anmeldung, Veröffentlichung und Absage — ohne Transaktion kein Rollback

Entscheidend ist, was **nicht** fehlschlägt: die einfachen Kapazitätstests bleiben grün. Der
Nebenläufigkeitstest ist also kein falsch positiver Test, sondern prüft genau den Schutz.

### Probe B: Kapazitätsregel selbst entfernen

Den Zweig `elsif full?` aus `Concert#register` löschen.

Ergebnis (geprüft am 23.09.2026, damals 250 Tests): **5 Fehler von 250 Tests**, unter anderem
`ConcertTest#test_rejects_a_registration_for_a_full_concert` und
`RegistrationsControllerTest#test_a_full_concert_is_rejected`.

### Danach

`bin/rails test` muss wieder **0 Fehler** melden (aktuell 253 Tests) und `git diff` leer sein.

---

## 7. Manuelle Prüfungen

Automatische Tests decken die Regeln ab; diese Liste deckt Abläufe, Darstellung und Bedienung.
Sie hat zwei Teile: die Abläufe über HTTP sind geprüft, die Sichtprüfung im Browser ist offen.

### 7.1 Abläufe über HTTP — geprüft

Durchgang am 23.09.2026 mit `bin/dev` in einer frischen Kopie nach `bin/setup --skip-server`,
angemeldet mit den Demo-Konten. Die Schritte liefen als echte HTTP-Anfragen gegen den Server.
Geprüft wurden Weiterleitung, Statuscode, Meldungen und die ausgelieferte HTML-Seite. Wie die
Seiten aussehen und sich bedienen lassen, sagt dieser Teil nicht aus. Das deckt 7.2 ab.

| # | Prüfung | Erwartung | Ergebnis | OK |
|---|---|---|---|:--:|
| 1 | Profil öffnen, Namen ändern | Änderung wird übernommen und bestätigt | „Dein Profil wurde gespeichert.", neuer Name im Formular | ☑ |
| 2 | Passwort mit falschem aktuellem Passwort ändern | verständliche deutsche Fehlermeldung, kein Wechsel | 422 mit „Aktuelles Passwort ist nicht korrekt", Passwortfelder leer, Login mit altem Passwort gelingt weiter | ☑ |
| 3 | E-Mail-Adresse ändern | neue Adresse erst nach Bestätigung aktiv (Link im Entwicklungslog) | Profil zeigt die ausstehende Adresse, Login damit scheitert. Link steht im Log. Nach dem Öffnen: „Deine E-Mail-Adresse wurde auf … geändert.", Login mit neuer Adresse gelingt, mit alter nicht. Derselbe Link ein zweites Mal und ein erfundener Link: „Dieser Bestätigungslink ist ungültig oder abgelaufen." | ☑ |
| 4 | Konzertformular leer absenden | Fehler stehen gesammelt und auf Deutsch über dem Formular | 422, Fehlerblock vor den Feldern: Titel, Kapazität, Beginn, Ende | ☑ |
| 5 | Konzert mit ungültigem Zeitraum speichern (Ende vor Beginn) | wird abgewiesen | „Ende muss nach dem Beginn liegen" | ☑ |
| 6 | Setlist mehrzeilig erfassen | Detailseite zeigt eine Zeile je Lied in der erfassten Reihenfolge | Drei Zeilen erscheinen als nummerierte Liste in der erfassten Reihenfolge | ☑ |
| 7 | Playlist-Link setzen | Link öffnet extern; ohne Link erscheint kein leerer Verweis | Link mit `target="_blank"` und `rel="noopener"`. Ohne Link kein Verweis. `javascript:`-Adresse wird abgewiesen | ☑ |
| 8 | Volles Konzert anmelden | verständliche Meldung statt technischer Fehler | „Dieses Konzert ist bereits ausgebucht." | ☑ |
| 9 | Navigation als Teilnehmer | keine Konzertverwaltung, keine Aktivitäten, keine Benutzerverwaltung | Navigation nur Konzerte, Meine Anmeldungen, Profil. Direkter Aufruf von Neues Konzert, Bearbeiten, Teilnehmerliste, Aktivitäten, Benutzerverwaltung und Löschen: „Für diese Aktion fehlt dir die Berechtigung." | ☑ |
| 10 | Navigation als Organisator und als Administrator | Verwaltung sichtbar; Benutzerverwaltung nur beim Administrator | Organisator: Aktivitäten, keine Benutzerverwaltung, direkter Aufruf abgewiesen. Admin: beides | ☑ |
| 11 | Abmelden, danach geschützte Seite aufrufen | Weiterleitung auf die Anmeldung | „Du wurdest abgemeldet.", Profil leitet auf die Anmeldung um | ☑ |
| 12 | Buchung | Anmeldung gelingt, doppelte Anmeldung wird abgewiesen | „Du bist für Jazz Night angemeldet.", danach „Du bist für dieses Konzert bereits angemeldet." Konzert erscheint unter Meine Anmeldungen und in der Teilnehmerliste | ☑ |
| 13 | Stornierung | Platz wird frei, Aktivität wird protokolliert | „Deine Anmeldung für Jazz Night wurde storniert." Der freie Platz ist sofort wieder buchbar. Aktivitäten zeigen Anmeldung und Stornierung mit Person und Zeitpunkt | ☑ |
| 14 | Abgesagtes Konzert | keine Anmeldung möglich, verständliche Meldung | Hinweis „Dieses Konzert wurde abgesagt …", keine Schaltfläche zum Anmelden. Eine direkte Anfrage wird abgewiesen mit „Dieses Konzert wurde abgesagt." Ein Entwurf bleibt bei der allgemeinen Berechtigungsmeldung | ☑ |
| 15 | Bearbeitungskonflikt | veraltete Version wird abgewiesen, Eingaben bleiben, neuere Daten bleiben erhalten | Admin und Organisatorin öffnen dasselbe Konzert, der Admin speichert zuerst. Die Organisatorin erhält 409 mit „Dieses Konzert wurde zwischenzeitlich geändert. Deine Eingaben wurden nicht gespeichert.", ihre Eingaben stehen noch im Formular, dazu „Aktuellen Stand neu laden". Gespeichert bleibt der Titel des Admins | ☑ |
| 16 | Benutzerverwaltung als Admin | Name und Rolle eines anderen Benutzers änderbar, E-Mail-Wechsel erst nach Bestätigung, eigene Rolle gesperrt | „Tim Organisator wurde gespeichert.", neue Rolle wirkt sofort in der Navigation. Den Bestätigungslink aus dem Log öffnet der betroffene Benutzer ohne Sitzung, danach gilt die neue Adresse. Beim eigenen Konto gibt es kein Rollenfeld | ☑ |
| 17 | Benutzerverwaltung direkt aufrufen | Organisator und Teilnehmer werden abgewiesen | `/admin/users` und `/admin/users/1/edit` leiten beide Rollen mit „Für diese Aktion fehlt dir die Berechtigung." auf die Startseite um | ☑ |
| 18 | Registrierung | neues Konto mit Rolle Teilnehmer | „Willkommen bei EventDesk, Neu Teilnehmer.", Navigation ohne Verwaltung | ☑ |

Ein begonnenes Konzert lässt sich über die Oberfläche nicht herstellen. Seine Meldung „Dieses
Konzert hat bereits begonnen." prüfen deshalb nur die Tests in
`test/controllers/registrations_controller_test.rb`.

### 7.2 Sichtprüfung im Browser — offen

Noch nicht durchgeführt. Mit den Demo-Konten im Browser durchgehen:

| # | Prüfung | Erwartung | OK |
|---|---|---|:--:|
| B1 | Login, Registrierung, Profil, Passwort, E-Mail ändern | Formulare lesbar und bedienbar, Pflichtfelder markiert, Passwortfelder nach Fehler leer | ☐ |
| B2 | Konzertliste und Detailseite als Teilnehmer | Status, Zeitraum und freie Plätze gut erkennbar, Setlist als Liste, Playlist-Link öffnet neuen Tab | ☐ |
| B3 | Anmelden und Stornieren | Erfolgs- und Fehlermeldungen oben gut sichtbar, Rückfrage vor dem Stornieren erscheint | ☐ |
| B4 | Konzert erstellen, bearbeiten, veröffentlichen, absagen, Entwurf löschen | Schaltflächen passen zum Status, Rückfragen erscheinen, Fehlerblock über dem Formular | ☐ |
| B5 | Bearbeitungskonflikt in zwei Fenstern | Konfliktmeldung gut sichtbar, Eingaben bleiben stehen, „Aktuellen Stand neu laden" funktioniert | ☐ |
| B6 | Teilnehmerliste, Aktivitäten, Benutzerverwaltung | Tabellen lesbar, Änderungen bei Aktivitäten verständlich dargestellt | ☐ |
| B7 | Navigation je Rolle | Nur die erlaubten Einträge sichtbar | ☐ |

Nebenbei bestätigt: Nach zehn Login-Versuchen in drei Minuten greift die Sperre gegen zu viele
Anmeldeversuche.

Die Punkte 9, 10, 16 und 17 aus 7.1 schliessen zugleich die manuellen Durchgänge aus
`docs/spec/04-user-management/tasks.md` und `docs/spec/05-policies/tasks.md` ab.
