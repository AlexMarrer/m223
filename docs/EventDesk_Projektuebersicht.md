# EventDesk – Projektübersicht

> Arbeitsgrundlage für die Umsetzung mit Claude Code  
> Modul 223 – Multi-User-Applikationen objektorientiert realisieren

## 1. Zweck dieses Dokuments

Dieses Dokument ist die zentrale technische und fachliche Übersicht für die Umsetzung von **EventDesk**.

Für jede Projektaufgabe soll Claude Code zuerst anhand dieses Dokuments eine eigene, konkrete Spezifikation und einen Umsetzungsplan erstellen. Die Umsetzung soll erst danach erfolgen.

Die Aufgaben orientieren sich an der empfohlenen Reihenfolge des Unterrichts:

### Tag 3

1. Datenbank und Modelle erstellen
2. Benutzerauthentifizierung implementieren
3. Benutzerprofil implementieren
4. Benutzerverwaltung implementieren

### Tag 4

5. Benutzerrollen und Berechtigungen implementieren
6. Kernfunktion implementieren
7. Aktivitätsprotokoll implementieren
8. Testing

---

# 2. Projektziel

**EventDesk** ist eine serverseitige Webanwendung zur Verwaltung von Konzerten mit begrenzten Plätzen.

Benutzer können veröffentlichte Konzerte ansehen und sich dafür anmelden. Organisatoren verwalten Konzerte und Teilnehmerlisten. Administratoren können zusätzlich Benutzer und Rollen verwalten.

Der wichtigste Multi-User-Fall ist die gleichzeitige Buchung des letzten freien Platzes:

> Wenn zwei verschiedene Benutzer gleichzeitig den letzten freien Platz buchen, darf genau eine Anmeldung entstehen.

Die erste Iteration ist für ungefähr drei Entwicklungstage geplant.

---

# 3. Technischer Rahmen

- Ruby on Rails 8.1
- serverseitig gerenderte Rails Views
- SQLite
- Pundit für Autorisierung
- Rails Authentication Generator als Basis für Login und Sessions
- Rails-Testframework
- keine separate API und kein separates Frontend geplant

Technische Zusatzdaten für Sessions und E-Mail-Bestätigungen können während der Umsetzung ergänzt werden.

## Konventionen

### Sprache

- **Code ist Englisch**: Models, Attribute, Methoden, Routes, Controller, Policies, Tests, Kommentare, Commit-Messages.
- **UI ist Deutsch**: alle benutzersichtbaren Texte — Views, Beschriftungen, Buttons, Flash-Meldungen, Validierungsfehler.
- Übersetzungen liegen in `config/locales/de.yml`. Keine deutschen Strings fest in Models oder Controllern.

### Namensentscheidungen

Bewusst getroffen. Änderungen erfordern eine Anpassung des Projektantrags:

| Name | Entscheidung | Begründung |
|---|---|---|
| `Concert` | statt `Event` | EventDesk verwaltet ausschliesslich Konzerte. `Event` ist generisch und kollidiert mit dem Programmierbegriff. |
| `Registration` | statt `Booking` beibehalten | Eine Konzertanmeldung umfasst keine Zahlung, kein Ticket und keine Sitzplatzbuchung. |
| `creator_id` | statt `organizer_id` beibehalten | Ein Konzert kann von einem Organisator *oder* einem Admin erstellt werden. `creator_id` benennt den Ersteller, ohne eine Rolle zu implizieren. |
| `Activity` | beibehalten | Entspricht exakt dem UI-Begriff „Aktivitäten" (S14). |

`EventDesk` bleibt der Produktname und wird nicht umbenannt.

### Glossar (UI Deutsch ↔ Code Englisch)

| UI (Deutsch) | Code (Englisch) |
|---|---|
| Konzert | `Concert` |
| Anmeldung (zu einem Konzert) | `Registration` |
| Teilnehmer | `User` mit Rolle `user` |
| Organisator | Rolle `organizer` |
| Administrator | Rolle `admin` |
| Ersteller | `creator` |
| Entwurf / Veröffentlicht / Abgesagt | `draft` / `published` / `cancelled` |
| Kapazität | `capacity` |
| Freie Plätze | `free_seats` |
| Setlist | `setlist` |
| Playlist-Link | `playlist_url` |
| Beginn / Ende | `starts_at` / `ends_at` |
| Teilnehmerliste | Teilnehmerliste (participant list) |
| Aktivität | `Activity` |

### Begriffsabgrenzung

Das Deutsche benutzt je ein Wort für zwei verschiedene Fachbegriffe. Im Code sind sie zu trennen:

- **„Anmelden"** heisst *einloggen* (`Session`) **und** *sich für ein Konzert anmelden* (`Registration`). Die Kontoerstellung heisst „Konto erstellen" (`User`).
- **„Stornieren"** storniert eine `Registration` (Datensatz wird gelöscht). **„Absagen"** sagt ein `Concert` ab (Status wird `cancelled`, Anmeldungen bleiben erhalten). Nie ein blosses `cancel` für beides verwenden.

---

# 4. Rollen

Übersicht, wer was verwalten darf. Diese Tabelle ist massgebend; bei Widersprüchen in anderen Dokumenten gilt sie.

| | Teilnehmer (`user`) | Organisator (`organizer`) | Administrator (`admin`) |
|---|:---:|:---:|:---:|
| Veröffentlichte Konzerte ansehen, anmelden, eigene Anmeldung stornieren, eigenes Profil bearbeiten | ✅ | ✅ | ✅ |
| **Konzerte verwalten** (erstellen, bearbeiten, Entwürfe löschen, veröffentlichen, absagen) | ❌ | ✅ | ✅ |
| Teilnehmerlisten und Aktivitätsfeed einsehen | ❌ | ✅ | ✅ |
| **Benutzer und Rollen verwalten** | ❌ | ❌ | ✅ |

Organisatoren verwalten Konzerte, aber niemals Benutzer. Nur Admins verwalten Benutzer und Rollen. Niemand darf die eigene Rolle ändern.

## User

Ein normaler Benutzer kann:

- sich registrieren
- sich anmelden und abmelden
- veröffentlichte Konzerte ansehen
- Konzertdetails ansehen
- sich für ein Konzert anmelden
- eigene Anmeldungen stornieren
- eigene Anmeldungen ansehen
- das eigene Profil bearbeiten
- das eigene Passwort ändern
- eine neue E-Mail-Adresse bestätigen

## Organisator

Ein Organisator besitzt zusätzlich die Rechte, um:

- Konzerte zu erstellen
- Konzerte zu bearbeiten
- Konzertentwürfe zu löschen
- Konzerte zu veröffentlichen
- veröffentlichte Konzerte abzusagen
- Teilnehmerlisten einzusehen
- den Aktivitätsfeed einzusehen

Organisatoren dürfen sich ebenfalls selbst für Konzerte anmelden.

## Admin

Ein Admin besitzt alle Rechte eines Organisators und kann zusätzlich:

- alle Benutzer einsehen
- Namen anderer Benutzer ändern
- E-Mail-Adressen anderer Benutzer ändern
- Rollen anderer Benutzer ändern

Die eigene Rolle darf nicht geändert werden.

Eine geänderte E-Mail-Adresse wird erst nach Bestätigung durch den betroffenen Benutzer aktiv.

---

# 5. Fachliches Datenmodell

## User

Vorgesehene fachliche Daten:

- `id`
- `name`
- `email_address`
- `role`
- `password_digest`

Regeln:

- E-Mail-Adresse ist eindeutig
- neue Benutzer erhalten standardmässig die Rolle `user`
- Rollen: `user`, `organizer`, `admin`
- Passwort mindestens 12 Zeichen
- Passwörter werden nicht im Klartext gespeichert

## Concert

Ein `Concert` ist die zentrale fachliche Entität: ein terminiertes Konzert mit begrenzter Kapazität.

Vorgesehene Daten:

- `id`
- `creator_id`
- `title`
- `description`
- `setlist`
- `playlist_url`
- `capacity`
- `status`
- `starts_at`
- `ends_at`
- `lock_version`

Regeln:

- Kapazität muss positiv sein
- Ende muss nach dem Beginn liegen
- Playlist-Link ist optional
- Setlist wird als Text gespeichert, ein Song pro Zeile
- `creator_id` verweist auf den erstellenden Benutzer

Statusfolge:

`draft -> published -> cancelled`

Zusätzliche Regeln:

- nur Entwürfe dürfen gelöscht werden
- Bearbeiten, Veröffentlichen und Absagen ist nur vor Konzertbeginn möglich
- abgesagte Konzerte bleiben als Historie bestehen
- bestehende Anmeldungen eines abgesagten Konzerts bleiben erhalten

## Registration

Eine `Registration` verbindet genau einen Benutzer mit genau einem Konzert.

Vorgesehene Daten:

- `id`
- `user_id`
- `concert_id`
- `created_at`

Regeln:

- pro Benutzer und Konzert höchstens eine Anmeldung
- Kombination aus `user_id` und `concert_id` ist eindeutig
- stornierte Anmeldungen werden gelöscht
- freie Plätze werden aus `capacity - Anzahl Registrations` berechnet

## Activity

Eine `Activity` protokolliert relevante Aktionen an einem Konzert.

Vorgesehene Daten:

- `id`
- `actor_id`
- `concert_id`
- `action`
- `details`
- `created_at`

Bei Änderungen eines veröffentlichten Konzerts enthält `details` die alten und neuen Werte der geänderten Angaben.

---

# 6. Zentrale Geschäftsregeln

## Konzertanmeldung

Eine Anmeldung ist nur möglich, wenn:

- der Benutzer angemeldet ist
- das Konzert veröffentlicht ist
- das Konzert noch nicht begonnen hat
- das Konzert nicht abgesagt ist
- mindestens ein Platz frei ist
- der Benutzer noch nicht für dieses Konzert angemeldet ist

Bei Erfolg werden Anmeldung und zugehöriger Activity-Eintrag gemeinsam gespeichert.

## Stornierung

Ein Benutzer darf nur die eigene Anmeldung stornieren.

Eine Stornierung ist nur möglich, wenn:

- das Konzert veröffentlicht ist
- das Konzert noch nicht begonnen hat

Danach wird der Platz wieder frei.

Eine erneute Anmeldung ist möglich, sofern wieder ein Platz verfügbar ist.

## Gleichzeitige Buchungen

Kapazitätsprüfung und Speichern müssen gegen parallele Zugriffe geschützt sein.

Bei zwei gleichzeitigen gültigen Buchungsversuchen für den letzten Platz gilt:

- genau eine Anmeldung wird gespeichert
- die andere Anfrage wird abgewiesen
- es darf keine Überbuchung entstehen

Der aktuelle Stand von Status und Belegung muss innerhalb der geschützten Transaktion aus der Datenbank gelesen werden.

## Transaktionen

Folgende Änderungen sollen atomar erfolgen:

- Anmeldung + Activity
- Stornierung + Activity
- Veröffentlichung + Activity
- Änderung eines veröffentlichten Konzerts + Activity
- Absage + Activity

Wenn ein Teil fehlschlägt, wird die gesamte Änderung zurückgerollt.

Entwürfe und Änderungen an Benutzern werden nicht im Activity-Log protokolliert.

## Gleichzeitiges Bearbeiten

Für Konzerte wird Optimistic Locking mit `lock_version` verwendet.

Wenn ein Benutzer versucht, eine veraltete Version eines Konzerts zu speichern:

- wird die Änderung abgewiesen
- neuere Daten werden nicht überschrieben
- die bisherigen Eingaben sollen sichtbar bleiben
- der aktuelle Datenstand kann neu geladen werden

---

# 7. Funktionen der ersten Iteration

## P1

### Benutzerkonto

- Registrierung mit Name, eindeutiger E-Mail-Adresse und Passwort
- Login
- Logout
- eigenes Profil bearbeiten
- Passwort ändern
- neue E-Mail-Adresse bestätigen

### Konzerte

- kommende veröffentlichte und abgesagte Konzerte anzeigen
- Beschreibung anzeigen
- Zeitraum anzeigen
- Status anzeigen
- freie Plätze anzeigen
- Setlist anzeigen
- optionalen Playlist-Link anzeigen
- eigene angemeldete Konzerte auch nach Konzertbeginn öffnen

### Anmeldungen

- für ein Konzert anmelden
- doppelte Anmeldung verhindern
- Anmeldung bei vollem Konzert verhindern
- eigene Anmeldung stornieren
- nach Stornierung erneut anmelden

### Konzertverwaltung

Organisator und Admin:

- Konzert erstellen
- Konzert bearbeiten
- Entwurf löschen
- Konzert veröffentlichen
- veröffentlichtes Konzert absagen

### Benutzerverwaltung

Nur Admin:

- Benutzer auflisten
- Namen ändern
- E-Mail-Adresse ändern
- Rollen ändern
- eigene Rolle nicht ändern können

### Sicherheit und Konsistenz

- serverseitige Berechtigungsprüfung
- keine Überbuchung
- Transaktionen
- Activity-Log

## P2

- Teilnehmerliste eines Konzerts
- verständliche Fehlermeldungen für ungültige Buchungen
- Activity-Details mit alten und neuen Werten
- Konflikterkennung beim gleichzeitigen Bearbeiten eines Konzerts

P1 wird zuerst umgesetzt. P2 gehört weiterhin zum geplanten Umfang, wird aber erst danach umgesetzt.

---

# 8. Nicht Teil der ersten Iteration

Folgende Funktionen sind ausdrücklich nicht vorgesehen:

- Wartelisten
- Zahlungen
- Kalenderintegration
- QR-Codes
- Datei-Uploads
- Konzertbenachrichtigungen
- Erinnerungen
- Spotify- oder andere Playlist-Integrationen innerhalb der Anwendung

Ein Playlist-Link öffnet lediglich eine externe Playlist.

Für die Entwicklung genügt es, den Link zur E-Mail-Bestätigung im Entwicklungslog bereitzustellen.

---

# 9. Aufgabenplan

## Aufgabe 1 – Datenbank und Modelle erstellen

### Ziel

Die fachliche Grundlage der Anwendung erstellen.

### Enthalten

- Migrationen
- Models
- Beziehungen
- Validierungen
- Datenbank-Constraints
- Rollen
- Konzertstatus
- Eindeutigkeit der Anmeldung
- `lock_version`
- Seed für mindestens ein Adminkonto

### Relevante Modelle

- `User`
- `Concert`
- `Registration`
- `Activity`

### Besonders wichtig

Regeln sollen nicht nur in der Oberfläche geprüft werden. Kritische Datenregeln müssen auch im Model beziehungsweise in der Datenbank abgesichert sein.

---

## Aufgabe 2 – Benutzerauthentifizierung implementieren

### Ziel

Registrierung und sichere Anmeldung bereitstellen.

### Enthalten

- Rails Authentication Generator verwenden
- Registrierung ergänzen
- Login
- Logout
- geschützte Seiten
- eindeutige E-Mail-Adresse
- Passwort mit mindestens 12 Zeichen

### Erwartetes Verhalten

- gültiger Login funktioniert
- ungültiger Login wird abgewiesen
- nicht angemeldete Benutzer erhalten keinen Zugriff auf geschützte Bereiche

---

## Aufgabe 3 – Benutzerprofil implementieren

### Ziel

Benutzer können die eigenen Kontodaten verwalten.

### Enthalten

- Namen ändern
- neue E-Mail-Adresse erfassen
- E-Mail-Änderung bestätigen
- Passwort ändern
- aktuelle Rolle anzeigen

### Regeln

- Rolle ist im eigenen Profil nicht bearbeitbar
- Passwortänderung verlangt das aktuelle Passwort
- neues Passwort hat mindestens 12 Zeichen
- neue E-Mail-Adresse wird erst nach Bestätigung aktiv

---

## Aufgabe 4 – Benutzerverwaltung implementieren

### Ziel

Administratoren können andere Benutzer verwalten.

### Enthalten

- Benutzerliste
- Benutzer bearbeiten
- Name ändern
- E-Mail-Adresse ändern
- Rolle ändern

### Regeln

- nur Admins dürfen die Benutzerverwaltung benutzen
- eigene Rolle darf nicht geändert werden
- neue E-Mail-Adresse wird erst nach Bestätigung durch den betroffenen Benutzer aktiv
- Organisatoren besitzen keine Benutzerverwaltungsrechte

---

## Aufgabe 5 – Benutzerrollen und Berechtigungen implementieren

### Ziel

Alle geschützten Aktionen serverseitig korrekt autorisieren.

### Technik

- Pundit

### Zu prüfen

User darf nicht:

- Konzerte verwalten
- fremde Anmeldungen stornieren
- Teilnehmerlisten öffnen
- Activity-Feed öffnen
- Benutzer verwalten

Organisator darf zusätzlich:

- Konzerte verwalten
- Teilnehmerlisten öffnen
- Activity-Feed öffnen

Admin darf zusätzlich:

- Benutzer verwalten
- Rollen anderer Benutzer ändern

Die Oberfläche darf Aktionen abhängig von der Rolle ausblenden oder deaktivieren. Die eigentliche Sicherheit muss jedoch serverseitig erzwungen werden.

---

## Aufgabe 6 – Kernfunktion implementieren

### Ziel

Die eigentliche EventDesk-Funktionalität umsetzen.

### Teil A – Konzertverwaltung

- Konzert erstellen
- bearbeiten
- veröffentlichen
- absagen
- Entwurf löschen
- Konzertdetails anzeigen
- Statusregeln beachten
- Kapazität nicht unter aktuelle Belegung reduzieren
- Setlist verwalten
- optionalen Playlist-Link verwalten

### Teil B – Konzertanmeldung

- anmelden
- eigene Anmeldung stornieren
- freie Plätze berechnen
- doppelte Anmeldung verhindern
- volle Konzerte ablehnen
- abgesagte Konzerte ablehnen
- begonnene Konzerte ablehnen

### Teil C – Multi-User-Konsistenz

Der kritische Use Case ist die Buchung des letzten freien Platzes.

Die Lösung muss gewährleisten:

> Zwei parallele gültige Buchungsversuche für den letzten Platz erzeugen genau eine Registration.

Zusätzlich wird bei Konzertänderungen `lock_version` für Optimistic Locking verwendet.

---

## Aufgabe 7 – Aktivitätsprotokoll implementieren

### Ziel

Relevante Änderungen nachvollziehbar machen.

### Zu protokollierende Aktionen

- Anmeldung
- Stornierung
- Veröffentlichung eines Konzerts
- Änderung eines veröffentlichten Konzerts
- Absage eines Konzerts

### Activity enthält

- ausführenden Benutzer
- Konzert
- Aktion
- Zeitpunkt
- bei Konzertänderungen alte und neue Werte

### Wichtig

Activity und eigentliche Datenänderung müssen innerhalb derselben Transaktion gespeichert werden.

Wenn der Activity-Eintrag fehlschlägt, darf auch die eigentliche Änderung nicht bestehen bleiben.

---

## Aufgabe 8 – Testing

### Ziel

Die zentralen Regeln und Sicherheitsanforderungen automatisiert absichern.

### Automatisiert prüfen

#### Models

- Validierungen
- Beziehungen
- eindeutige Anmeldung
- Buchungsregeln

#### Authentication / Requests

- gültiger Login
- ungültiger Login
- Zugriff ohne Session

#### Policies / Berechtigungen

- erlaubte Requests
- verweigerte Requests
- fremde Daten
- Rollen

#### Kernfunktion

- gültige Anmeldung
- doppelte Anmeldung
- volles Konzert
- abgesagtes Konzert
- begonnenes Konzert
- Stornierung
- erneute Anmeldung nach Stornierung

#### Parallelität

Zwei synchronisierte Buchungsversuche verschiedener Benutzer für den letzten freien Platz müssen genau eine erfolgreiche Buchung ergeben.

Der Test soll mit getrennten Datenbankverbindungen und ohne umschliessende Testtransaktion ausgeführt werden.

#### Transaktionen

Wenn das Speichern einer Activity absichtlich fehlschlägt, muss auch die zugehörige Datenänderung zurückgerollt werden.

#### Konzertstatus

- nur Entwürfe sind löschbar
- veröffentlichte Konzerte können vor Beginn abgesagt werden
- Anmeldungen bleiben nach einer Absage erhalten

#### Optimistic Locking

Eine veraltete Konzertversion darf neuere Daten nicht überschreiben.

### Zusätzlich manuell prüfen

- Profile
- Formulare
- Setlists
- Playlist-Links
- Fehlermeldungen
- grundlegende Navigation

---

# 10. Vorgesehene Screens

Die genaue Gestaltung ist nicht zentral. Folgende Screens sind fachlich vorgesehen:

- S01 Login
- S02 Registrierung
- S03 Konzertübersicht
- S04 Konzertdetails
- S05 Meine Anmeldungen
- S06 Mein Profil
- S07 Passwort ändern
- S08 E-Mail bestätigen
- S09 Konzertverwaltung
- S10 Konzert erstellen / bearbeiten
- S11 Teilnehmerliste
- S12 Benutzerverwaltung
- S13 Benutzer bearbeiten
- S14 Aktivitäten

Formulare für Erstellen und Bearbeiten sollen wenn sinnvoll wiederverwendet werden.

---

# 11. Reihenfolge und Abhängigkeiten

Die Aufgaben sollen grundsätzlich in dieser Reihenfolge umgesetzt werden:

```text
1. Models / Datenbank
        ↓
2. Authentication
        ↓
3. Profil
        ↓
4. Benutzerverwaltung
        ↓
5. Policies / Rollen
        ↓
6. Kernfunktion
        ↓
7. Activity Log
        ↓
8. Tests vervollständigen
```

Tests müssen nicht vollständig bis Aufgabe 8 aufgeschoben werden.

Bei jeder Aufgabe sollen bereits passende Tests ergänzt werden. Aufgabe 8 dient dazu, die gesamte Anwendung nochmals systematisch gegen die Anforderungen zu prüfen und fehlende Tests zu ergänzen.

---

# 12. Arbeitsweise mit Claude Code

Claude Code soll nicht direkt grosse Teile der Anwendung auf einmal implementieren.

Für jede der acht Aufgaben wird zuerst eine separate Spezifikation erstellt.

## Erwartete Struktur einer Aufgaben-Spezifikation

```markdown
# Aufgabe X – Titel

## Ziel

Was soll nach dieser Aufgabe funktionieren?

## Ausgangslage

Welche relevanten Teile des Projekts existieren bereits?

## Anforderungen

Welche Regeln aus der Projektübersicht betreffen diese Aufgabe?

## Geplante Änderungen

Welche Models, Controller, Views, Policies, Migrationen, Routes oder Tests werden voraussichtlich geändert oder erstellt?

## Technische Entscheidungen

Wie soll die Aufgabe technisch umgesetzt werden und warum?

## Randfälle

Welche Fehlerfälle und Sonderfälle müssen berücksichtigt werden?

## Tests

Welche automatisierten und manuellen Prüfungen werden benötigt?

## Akzeptanzkriterien

Konkrete überprüfbare Bedingungen, wann die Aufgabe abgeschlossen ist.

## Umsetzungsschritte

Kleine, logisch geordnete Schritte.

## Offene Fragen

Nur Punkte, die vor der Umsetzung tatsächlich noch geklärt werden müssen.
```

---

# 13. Regeln für Claude Code

Beim Erstellen eines Plans oder einer Spezifikation gelten folgende Regeln:

1. Diese Projektübersicht ist die fachliche Grundlage.
2. Bestehenden Code zuerst analysieren, bevor Änderungen geplant werden.
3. Keine neuen Features erfinden.
4. Den Scope der aktuellen Aufgabe einhalten.
5. P1 vor P2 behandeln.
6. Kritische Geschäftsregeln serverseitig absichern.
7. Datenbank-Constraints verwenden, wenn eine Regel auch auf Datenbankebene abgesichert werden sollte.
8. Berechtigungen nicht nur über ausgeblendete UI-Elemente lösen.
9. Bei Änderungen an bestehenden Entscheidungen Abweichungen ausdrücklich nennen.
10. Tests als Teil der Umsetzung mitplanen.
11. Keine unnötige Architektur oder Abstraktion hinzufügen.
12. Die Lösung soll für den begrenzten Umfang des Modulprojekts verständlich und wartbar bleiben.

---

# 14. Definition of Done für das Gesamtprojekt

EventDesk gilt fachlich als abgeschlossen, wenn:

- Benutzer sich registrieren und anmelden können
- Profile bearbeitet werden können
- die E-Mail-Änderung bestätigt werden muss
- Admins Benutzer verwalten können
- Rollen serverseitig korrekt durchgesetzt werden
- Organisatoren Konzerte verwalten können
- Benutzer sich für Konzerte anmelden und wieder abmelden können
- doppelte und ungültige Anmeldungen verhindert werden
- keine Überbuchung bei parallelen Buchungen möglich ist
- relevante Änderungen transaktional protokolliert werden
- veraltete Konzertänderungen erkannt werden
- die zentralen Regeln automatisiert getestet sind
- die Anwendung mit den im Projektantrag definierten Abläufen übereinstimmt
