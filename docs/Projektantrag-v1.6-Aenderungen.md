# Projektantrag EventDesk — Änderungen für Version 1.6

Grundlage: `Projektantrag_EventDesk_1-5.pdf` (Version 1.5, Status „Zur Beurteilung", 18.09.2026).

Diese Liste ist im Word-Dokument abzuarbeiten. Danach neu als PDF exportieren.
Die Änderungen sind bewusst dokumentiert, weil Bewertungskriterium 3 verlangt, dass die
Applikation der Dokumentation entspricht — Code und Antrag müssen am Ende übereinstimmen.

---

## 1. Kopfdaten

| Feld    | alt             | neu             |
| ------- | --------------- | --------------- |
| Version | 1.5             | 1.6             |
| Datum   | 18.09.2026      | 24.09.2026      |
| Status  | Zur Beurteilung | Zur Beurteilung |

Optional eine Änderungszeile ergänzen:

> Version 1.6: Entität `Event` in `Concert` umbenannt, Rollentabelle präzisiert, Feld für die
> ausstehende E-Mail-Adresse im Datenmodell ergänzt, Benutzerverwaltung in Abschnitt 1 und in
> den Breadboards auf Admins beschränkt, erreichten Stand ergänzt.

---

## 2. Umbenennung `Event` → `Concert`

**Begründung:** EventDesk verwaltet ausschliesslich Konzerte. `Event` ist ein generischer
Begriff und kollidiert mit der Programmierbedeutung des Wortes. `Concert` ist der
domänenspezifische Fachbegriff (Bewertungskriterium „Domänenspezifische Fachbegriffe verwendet").

**Wichtig:** Der Produktname **EventDesk bleibt unverändert**. Nur die Entität wird umbenannt.
In Word also _nicht_ blind „Alle ersetzen" über das ganze Dokument laufen lassen.

Die deutschen Fliesstexte sprechen ohnehin von „Konzert" und bleiben unverändert.
Betroffen sind nur die technischen Bezeichner:

### Abschnitt 3 — Gleichzeitige Anmeldungen

| alt                                                                                | neu                                                                                  |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `Event.transaction` verwendet im SQLite-Adapter von Rails 8.1 den IMMEDIATE-Modus. | `Concert.transaction` verwendet im SQLite-Adapter von Rails 8.1 den IMMEDIATE-Modus. |

### Abschnitt 4 — Datenmodell, Einleitungstext

| alt                                                                                                                                                                                                                | neu                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Das fachliche Datenmodell besteht aus vier Entitäten. **Event** steht für ein Konzert. **Registration** verbindet Benutzer und Konzerte. **Activity** protokolliert die Aktionen eines Benutzers an einem Konzert. | Das fachliche Datenmodell besteht aus vier Entitäten. **Concert** steht für ein Konzert. **Registration** verbindet Benutzer und Konzerte. **Activity** protokolliert die Aktionen eines Benutzers an einem Konzert. |

### Abschnitt 4 — ER-Diagramm (Grafik neu erzeugen)

| alt                                          | neu                           |
| -------------------------------------------- | ----------------------------- |
| Entitätsbox `EVENT Konzert`                  | `CONCERT`                     |
| `REGISTRATION` → `FK event_id`               | `FK concert_id`               |
| `REGISTRATION` → `UNIQUE(user_id, event_id)` | `UNIQUE(user_id, concert_id)` |
| `ACTIVITY` → `FK event_id`                   | `FK concert_id`               |

Der Zusatz „Konzert" in der Entitätsbox entfällt, weil der Name jetzt selbsterklärend ist.

### Beibehaltene Namen

Diese wurden geprüft und bewusst **nicht** geändert:

| Name           | Begründung                                                                                                                                           |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Registration` | Eine Konzertanmeldung umfasst keine Zahlung, kein Ticket und keine Sitzplatzbuchung. `Booking` wäre irreführend.                                     |
| `creator_id`   | Ein Konzert kann von einem Organisator _oder_ einem Admin erstellt werden. `organizer_id` würde eine Rolle implizieren, die nicht zwingend zutrifft. |
| `Activity`     | Entspricht exakt dem UI-Begriff „Aktivitäten" auf Screen S14.                                                                                        |

---

## 3. Abschnitt 3 — Rollentabelle korrigieren

**Problem:** Die Tabelle widerspricht Anforderung F05, den Breadboards (S09) und den
Wireframes (S09). Sie liest sich so, als dürften **nur Admins** Konzerte verwalten.
F05 sagt jedoch „Organisatoren & Admins erstellen und bearbeiten Konzerte".
Vier Stellen im Dokument gegen eine — die Tabelle ist die fehlerhafte Stelle.

### Alt

| Rolle           | Berechtigungen                                                                                         |
| --------------- | ------------------------------------------------------------------------------------------------------ |
| Teilnehmer      | Konzerte ansehen, sich selbst anmelden, eigene Anmeldungen stornieren und das eigene Profil bearbeiten |
| Organisator     | Zusätzlich alle Konzerte, Teilnehmerlisten und Aktivitäten **einsehen**                                |
| Administratoren | Können zusätzlich Benutzer **und Konzerte** verwalten                                                  |

### Neu

| Rolle         | Berechtigungen                                                                                                                                           |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Teilnehmer    | Konzerte ansehen, sich selbst anmelden, eigene Anmeldungen stornieren und das eigene Profil bearbeiten                                                   |
| Organisator   | Zusätzlich Konzerte verwalten (erstellen, bearbeiten, Entwürfe löschen, veröffentlichen, absagen) sowie Teilnehmerlisten und den Aktivitätsfeed einsehen |
| Administrator | Zusätzlich Benutzer und Rollen verwalten                                                                                                                 |

Kernaussage: **Organisatoren verwalten Konzerte, aber niemals Benutzer. Nur Admins verwalten
Benutzer und Rollen.** Niemand darf die eigene Rolle ändern.

Der Folgesatz „Nur Admins dürfen die Rollen anderer Benutzer ändern" bleibt unverändert und
ist jetzt konsistent mit der Tabelle.

---

## 4. Abschnitt 4 — Feld für ausstehende E-Mail-Adresse ergänzen

**Problem:** Die Wireframes verlangen es, das Datenmodell bildet es nicht ab.

- S06 „Mein Profil": _„Aktuelle Adresse und ausstehende Änderung anzeigen"_
- S08 „E-Mail bestätigen": Bestätigungslink
- S13 „Benutzer bearbeiten": _„Neue E-Mail muss bestätigt werden"_

Die Entität `USER` im ER-Diagramm kennt aber nur `id, name, email_address, role, password_digest`.
Es gibt kein Feld für die noch unbestätigte Adresse. Der Antrag schiebt das mit
„Technische Daten für Sitzungen und E-Mail-Bestätigungen werden bei der Umsetzung ergänzt"
auf — für Aufgabe 1 muss es aber entschieden sein.

### Änderung im ER-Diagramm

Entität `USER` um ein Feld erweitern:

```
USER
  PK id
  name
  email_address (eindeutig)
  unconfirmed_email (optional)
  role
  password_digest
```

### Ergänzender Satz in Abschnitt 4

> Eine neu erfasste E-Mail-Adresse wird als `unconfirmed_email` gespeichert und erst nach
> Bestätigung nach `email_address` übernommen. Der Bestätigungslink ist ein signierter,
> ablaufender Token und benötigt keine eigene Tabelle.

**Technischer Hintergrund:** Rails 8 bietet `generates_token_for :email_confirmation`.
Der Token wird aus dem Benutzerdatensatz abgeleitet und läuft automatisch ab. Es ist also
weder eine Token-Spalte noch eine Token-Tabelle nötig.

---

## 5. Abschnitt 2 — F05 um Pflichtangaben beim Veröffentlichen ergänzen

**Problem:** Der Antrag beschreibt Konzerte durchgehend mit Beschreibung und Setlist (F02, S04),
bezeichnet aber ausdrücklich **nur** den Playlist-Link als optional. Ob Beschreibung und
Setlist erzwungen werden, bleibt damit offen. Die Migration in Aufgabe 1 muss es entscheiden.

**Entscheidung:** Im Entwurf sind beide Felder frei, zum Veröffentlichen sind sie erforderlich.
Genau dafür existiert der Status „Entwurf" — ein Organisator soll ein Konzert terminieren
können, bevor das Programm feststeht. Ein veröffentlichtes Konzert ohne Setlist widerspräche
dagegen S04.

### Ergänzung in F05

An die bestehende Beschreibung von F05 anfügen:

> Beschreibung und Setlist sind zum Veröffentlichen erforderlich. Im Entwurf dürfen sie noch
> leer sein.

### Ergänzung bei den Konzertregeln (Ende Abschnitt 2)

Der Absatz „Konzertregeln:" endet mit „Abgesagte Konzerte und ihre Anmeldungen bleiben
unverändert als Historie erhalten." Dort anfügen:

> Beschreibung und Setlist müssen spätestens beim Veröffentlichen vorhanden sein und können
> danach nicht mehr geleert werden.

**Technische Fassung:** `docs/datenmodell.md`, Abschnitt 2. Umgesetzt als
`validates :description, :setlist, presence: true, unless: :draft?` — bewusst **ohne**
`NOT NULL`-Constraint, weil die Regel vom Status abhängt.

---

## 6. Optional — Abschnitt „Konventionen" ergänzen

Stärkt die Bewertungskriterien „Konventionen beachtet" und „Domänenspezifische Fachbegriffe
verwendet". Vorschlag als kurzer Abschnitt nach Abschnitt 1:

> **Sprachkonvention:** Der Code ist durchgehend englisch (Models, Attribute, Methoden,
> Routes, Tests). Die Benutzeroberfläche ist durchgehend deutsch. Übersetzungen liegen in
> `config/locales/de.yml`.
>
> **Begriffsabgrenzung:** „Anmelden" bezeichnet im Deutschen sowohl das Einloggen (`Session`)
> als auch die Konzertanmeldung (`Registration`). „Stornieren" betrifft eine `Registration`
> und löscht den Datensatz, „Absagen" betrifft ein `Concert` und setzt dessen Status auf
> `cancelled`, wobei bestehende Anmeldungen erhalten bleiben.

Das vollständige Glossar steht in `docs/EventDesk_Projektuebersicht.md`, Abschnitt
„Konventionen".

---

## 7. Abschnitt 1 — Benutzerverwaltung nur durch Admins

**Problem:** Die Aufzählung unter „Erste Iteration" schreibt die Benutzerverwaltung den
Organisatoren zu. Das widerspricht F08, dem Folgesatz in Abschnitt 3 und der Anwendung:
`UserPolicy#manage?` erlaubt die Benutzerverwaltung nur Admins.

| alt                                                                          | neu                                                                                                                                |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Verwaltung von Konzerten, Teilnehmerlisten und Benutzern durch Organisatoren | Verwaltung von Konzerten und Teilnehmerlisten durch Organisatoren und Admins, Verwaltung von Benutzern und Rollen nur durch Admins |

---

## 8. Abschnitt 5 — Breadboards an die Anwendung angleichen

**Problem 1:** S12 und S13 stehen unter „Organisatoren", und S09 führt für alle Verwaltenden
zu S12. Organisatoren erhalten in der Anwendung aber keinen Zugang zur Benutzerverwaltung.
Ein direkter Aufruf wird mit einer Meldung abgewiesen.

**Problem 2:** Einige Übergänge sind anders umgesetzt als skizziert. Die Anwendung hat eine
feste Navigation oben auf jeder Seite, statt „Zurück"-Links auf jeder Seite. Konzertliste und
Konzertverwaltung sind derselbe Screen.

### Neuer Einleitungssatz

Nach dem ersten Absatz von Abschnitt 5 anfügen:

> Jede Seite nach dem Login zeigt oben eine Navigation mit Konzerte (S03), Meine Anmeldungen
> (S05), Profil (S06) und Abmelden. Organisatoren und Admins sehen zusätzlich Aktivitäten (S14),
> Admins zusätzlich Benutzerverwaltung (S12).

### Änderungen je Screen

| Screen                | alt                                                                                                                                                               | neu                                                                                                                                                                                                                                                                                                |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S03                   | Details → S04. Meine Anmeldungen → S05. Profil → S06. Abmelden → S01. Verwaltung → S09, nur für Organisatoren.                                                    | Details → S04. Meine Anmeldungen, Profil und Abmelden über die Navigation. Für Organisatoren und Admins ist S03 zugleich S09.                                                                                                                                                                      |
| S04                   | Anmelden → S05.                                                                                                                                                   | Anmelden → S04 mit Bestätigung.                                                                                                                                                                                                                                                                    |
| S04                   | Zurück → S03 oder S05 je nach Einstieg.                                                                                                                           | Zurück → S03.                                                                                                                                                                                                                                                                                      |
| S05                   | Stornieren → aktualisierte Liste, nur vor Beginn bei veröffentlichtem Konzert. Zurück → S03.                                                                      | Stornieren → S04 mit Bestätigung, nur vor Beginn bei veröffentlichtem Konzert. Zurück über die Navigation.                                                                                                                                                                                         |
| S06                   | Eingabe: Name und neue E-Mail-Adresse. Rolle nur anzeigen.                                                                                                        | Eingabe: Name. Anzeige: aktuelle und ausstehende E-Mail-Adresse, Rolle.                                                                                                                                                                                                                            |
| S06                   | Neue E-Mail → Link im Entwicklungslog für S08. Passwort ändern → S07. Zurück → S03.                                                                               | E-Mail ändern → eigene Seite mit Eingabe der neuen Adresse, danach S06 und Link im Entwicklungslog für S08. Passwort ändern → S07.                                                                                                                                                                 |
| S09                   | Anzeige: alle Konzerte, auch Entwürfe.                                                                                                                            | S09 ist die Konzertliste S03 in der Ansicht für Organisatoren und Admins. Anzeige: alle Konzerte, auch Entwürfe und vergangene.                                                                                                                                                                    |
| S09                   | Neues Konzert oder bearbeiten → S10. Konzert öffnen → S04. Entwurf löschen → aktualisierte Liste. Benutzer → S12. Aktivitäten → S14. Zur Teilnehmeransicht → S03. | Neues Konzert oder bearbeiten → S10. Konzert öffnen → S04. Aktivitäten → S14 und, nur für Admins, Benutzerverwaltung → S12 über die Navigation.                                                                                                                                                    |
| S10                   | Entwurf speichern oder veröffentlichen → S04.                                                                                                                     | Speichern → S04. Ein neues Konzert ist zunächst ein Entwurf. Veröffentlicht wird auf S04.                                                                                                                                                                                                          |
| S04 für Organisatoren | Aktionen nach Konzertstatus: Bearbeiten → S10. Teilnehmerliste → S11. Veröffentlichtes Konzert vor Beginn absagen → S04 mit Status abgesagt. Zurück → S09.        | Aktionen nach Konzertstatus: Bearbeiten → S10. Teilnehmerliste → S11. Entwurf veröffentlichen → S04. Entwurf löschen → S09. Veröffentlichtes Konzert vor Beginn absagen → S04 mit Status abgesagt. Zurück → S09.                                                                                   |
| Zwischentitel vor S12 | –                                                                                                                                                                 | Neuer Zwischentitel **Administratoren** mit dem Satz: „Admins nutzen zusätzlich die Benutzerverwaltung. Organisatoren und Teilnehmer erhalten bei einem direkten Zugriff eine Meldung über fehlende Berechtigungen." S12 und S13 unter diesen Titel verschieben. S14 bleibt bei den Organisatoren. |
| S12                   | Anzeige: alle Benutzer mit Name, E-Mail-Adresse und Rolle. Bearbeiten → S13. Zurück zur Verwaltung → S09.                                                         | Nur für Admins. Anzeige: alle Benutzer mit Name, E-Mail-Adresse und Rolle. Bearbeiten → S13.                                                                                                                                                                                                       |
| S13                   | Eingabe: Name, neue E-Mail-Adresse und Rolle. Die eigene Rolle ist gesperrt.                                                                                      | Nur für Admins. Eingabe: Name und Rolle, die eigene Rolle ist gesperrt. Die neue E-Mail-Adresse hat ein eigenes Feld mit der Schaltfläche „Bestätigungslink senden".                                                                                                                               |
| S14                   | Konzert öffnen → S04. Zurück zur Verwaltung → S09.                                                                                                                | Konzert öffnen → S04. Zurück über die Navigation.                                                                                                                                                                                                                                                  |

S01, S02, S07, S08 und S11 stimmen mit der Anwendung überein.

### Wireframes (Abschnitt 6)

- „Benutzer und Aktivitäten": vermerken, dass die Benutzerverwaltung nur Admins angezeigt wird.
- „Verwaltung": Liegt eine eigene Skizze für S09 vor, den Satz ergänzen: „In der Umsetzung ist
  dies die Konzertliste mit zusätzlichen Aktionen für Organisatoren und Admins."
- Die Navigationsleiste oben muss nicht nachgezeichnet werden. Der Einleitungssatz in
  Abschnitt 5 genügt.

---

## 8a. Kleinere Präzisierungen in Abschnitt 2 und 3

| Stelle                                       | alt                                                                                       | neu                                                                                                   |
| -------------------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Abschnitt 3, Gleichzeitiges Bearbeiten       | Hat ein anderer Organisator das Konzert bereits verändert, wird das Speichern abgewiesen. | Hat ein anderer Organisator oder Admin das Konzert bereits verändert, wird das Speichern abgewiesen.  |
| Abschnitt 2, letzter Satz „Geplante Prüfung" | Geprüfte Anforderungen und Ergebnisse stehen unter /docs, der Testbefehl im README.       | Geprüfte Anforderungen und Ergebnisse stehen im Ordner docs/ des Code-ZIPs, der Testbefehl im README. |

---

## 9. Neuer Abschnitt — Erreichter Stand und Abweichungen

Als kurzen letzten Abschnitt anfügen. Inhalt aus `docs/abgabe-stand.md`, Abschnitte 1 und 3.

---

## 10. Prüfliste nach der Überarbeitung

- [ ] Version auf 1.6, Datum aktualisiert
- [ ] „EventDesk" steht noch überall dort, wo der Produktname gemeint ist
- [ ] Kein `Event`, `event_id` mehr als Entität oder Feld im Dokument
- [ ] ER-Diagramm neu exportiert und eingefügt
- [ ] Rollentabelle korrigiert und widerspruchsfrei zu F05
- [ ] `unconfirmed_email` im ER-Diagramm vorhanden
- [ ] F05 und Konzertregeln um Pflichtangaben beim Veröffentlichen ergänzt
- [ ] Abschnitt 1: Benutzerverwaltung nur durch Admins
- [ ] Abschnitt 5: Einleitungssatz zur Navigation, alle Zeilen aus Abschnitt 8 übernommen, S12/S13 unter „Administratoren"
- [ ] Abschnitt 6: Hinweise zu den Wireframes übernommen
- [ ] Präzisierungen aus Abschnitt 8a übernommen
- [ ] Abschnitt „Erreichter Stand und Abweichungen" ergänzt
- [ ] Als PDF exportiert, alte Version archiviert
