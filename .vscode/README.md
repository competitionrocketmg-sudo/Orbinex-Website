# Orbinex bijwerken vanuit VS Code

De enige websitebron is `index.html` in de hoofdmap. Deze VS Code-taak maakt na
het opslaan automatisch een commit van dat bestand en verstuurt die naar
`competitionrocketmg-sudo/Orbinex-Website`, branch `main`. GitHub Pages verzorgt
daarna de publicatie. De domeinnaam blijft apart afhankelijk van de DNS bij Combell.

## Eenmalig op je pc

1. Installeer Git als dit nog ontbreekt: https://git-scm.com/downloads.
   Git voor Windows bevat de Bash die deze taak gebruikt. Herstart VS Code na installatie.
2. Open in VS Code de opdrachtkiezer met `Ctrl+Shift+P`, kies `Git: Clone` en plak:
   `https://github.com/competitionrocketmg-sudo/Orbinex-Website.git`.
3. Kies een nieuwe map en open het gekloonde project. Bewerk voortaan de
   `index.html` uit deze map. Maak een kopie van eventuele nog niet opgeslagen
   wijzigingen in je oude map voordat je overstapt.
4. Vertrouw deze projectmap als VS Code dat vraagt. Sta de automatische taak toe.
   Verschijnt de vraag niet? Kies `Tasks: Manage Automatic Tasks` en
   `Allow Automatic Tasks`, en heropen de map. Je kunt de taak ook starten via
   `Tasks: Run Task` → `Orbinex: automatisch publiceren`.
5. Meld je aan bij GitHub wanneer Git daarom vraagt. Het account moet toegang
   hebben tot deze repository. De taak gebruikt de bestaande Git-aanmelding;
   er staan geen wachtwoorden of toegangstokens in deze bestanden.
6. Git heeft ook een naam en commit-e-mailadres nodig. Zijn die nog niet ingesteld,
   voer dan in de terminal van dit project deze opdrachten uit met je eigen gegevens:

   ```sh
   git config user.name "Jouw naam"
   git config user.email "Jouw GitHub commit-e-mailadres"
   ```

   Je commit-e-mailadres vind je bij https://github.com/settings/emails.
   Je kunt daar het GitHub-adres gebruiken dat je echte e-mailadres afschermt.

## Vanaf dan

- Bewerk de `index.html` in deze projectmap en druk op `Ctrl+S`.
- Na 5 seconden zonder een nieuwe opslag controleert de taak GitHub en verstuurt
  het opgeslagen bestand. GitHub Pages heeft daarna nog verwerkingstijd nodig.
- De terminal `Orbinex: automatisch publiceren` toont of het is gelukt.
- VS Code moet openstaan, de taak moet draaien en je pc moet internet hebben.
- Stop de taak via `Ctrl+C` in die terminal of `Tasks: Terminate Task`.

## Als de taak pauzeert

- **Nieuwere wijzigingen op GitHub:** stop de taak, haal die wijzigingen op via
  `Git: Pull`, los eventuele conflicten op en start de taak weer.
- **Aanmelding of verbinding mislukt:** herstel je GitHub-aanmelding/internet.
  De taak probeert opnieuw; je lokale wijzigingen en eventuele commit blijven bewaard.
- **Andere lokale commits:** publiceer die eerst zelf. De taak verstuurt alleen
  een reeks commits waarin uitsluitend `index.html` gewijzigd is.
- **Andere branch:** de taak publiceert uitsluitend vanaf `main`.

De taak gebruikt gewone pushes en respecteert Git-hooks. Andere gewijzigde of
klaargezette bestanden worden niet in de automatische commit opgenomen.

Documentatie: https://code.visualstudio.com/docs/debugtest/tasks#_run-behavior
