# Skrypt do naprawy i konserwacji systemu windows za pomocą PowerShell

Automatyczny skrypt w języku PowerShell przeznaczony do kompleksowej konserwacji, czyszczenia oraz naprawy systemu Windows 10/11. Projekt powstał w celu automatyzacji powtarzalnych zadań diagnostycznych i serwisowych.

---

## Funkcje

- **Czyszczenie dysku:** Usuwanie plików tymczasowych (`%TEMP%`) oraz opróżnianie Kosza.
- **Optymalizacja magazynu komponentów:** Czyszczenie niepotrzebnych kopii starych aktualizacji Windows (`WinSxS`).
- **Naprawa obrazu systemu:** Weryfikacja i odbudowa magazynu komponentów za pomocą narzędzia **DISM** (`RestoreHealth`).
- **Skanowanie spójności plików:** Naprawa uszkodzonych plików systemowych za pomocą **SFC** (`/scannow`).
- **Diagnostyka dysków:** Automatyczne wykrywanie partycji NTFS i skanowanie struktury plików w tle (**CHKDSK**).
- **Optymalizacja nośników:** Automatyczne wykonywanie polecenia **TRIM** dla dysków SSD lub defragmentacji dla dysków HDD.
- **Czyszczenie sieci:** Kasowanie pamięci podręcznej DNS (`Clear-DnsClientCache`).
- **Raportowanie:**
  - Wizualny pasek postępu u góry konsoli (`Write-Progress`).
  - Generowanie raportu ze znacznikami czasu na Pulpicie (np. `Raport_Konserwacji_2026-08-21_20-40.txt`).
  - Bezpieczne odliczanie do restartu komputera z możliwością anulowania (`CTRL+C`).

---

## Wymagania

- System operacyjny: **Windows 10** / **Windows 11**
- Uprawnienia: **administrator** (wymagane do uruchomienia narzędzi systemowych)
- Odblokowana możliwość wykonywania skryptów dla użytkownika (`ExecutionPolicy`)

---

## Instrukcja uruchomienia

1. Pobierz plik `Konserwacja.ps1` z repozytorium.
2. **Odblokuj uruchamianie skryptów PowerShell (czynność jednorazowa):**
   Otwórz PowerShell jako administrator i wykonaj polecenie:
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
3. Naciśnij prawym przyciskiem myszy na plik `Konserwacja.ps1` i wybierz opcje `uruchom za pomocą programu PowerShell`. Skrypt musi być uruchomiony z uprawnieniami administratora

---

## Uwagi

1. Skrypt nie powinien być uruchamiany zbyt często, gdyż wykonuje takie czynności jak defragmentacja/TRIM dysków, co przy zbyt częstym stosowaniu, może skrócić ich żywotność. Odpowiedni okres stosowania to 1-3 miesięcy
2. Skrypt nie usuwa stosu TCP/IP. W niektórych sytuacjach, może to naprawić działanie internetu. Powoduje to jednak przywrócenie ustawień karty sieciowej do fabrycznych, co może wymagać od użytkownika, przywrócenia ich poprzedniego stanu. Ponieważ skrypt miał być bezobsługowy, postanowiłem nie wprowadzać tej funkcji :)
3. Skrypt wykorzystuje jedynie wbudowane narzędzia systemu Windows do naprawy i czyszczenia plików
4. Skrypt usuwa stare wersje systemu windows, co uniemożliwia przywrócenie ich w razie ewentualnej awarii systemu w przyszłości
5. Skrypt nie przyśpiesza działania systemu i nie naprawia wszystkich istniejących problemów. Służy on do zwolnienia dodatkowego miejsca na dysku, wykrycia degradacji dysków na wczesnym etapie, zapobiegania ich spowolnieniu oraz naprawy plików systemowych.

---

## Naprawianie błędów

1. Zawieszanie się programu w losowym momencie. PowerShell posiada funkcję **Tryb Szybkiej Edycji**. Powoduje to zatrzymanie programu po naciśnięciu myszą lub zaznaczeniu fragmentu tekstu. Aby wznowić program, należy nacisnąć ENTER. Można też wyłączyć tą opcję poprzez naciśnięcie PPM na górny pasek PowerShell > Właściwości > Tryb Szybkiej Edycji > Wyłącz

---

## Licencja

Ten projekt jest udostępniany na licencji `MIT` — możesz go swobodnie używać, modyfikować i rozpowszechniać.  
Autor: Jeremiasz Chmielnicki  
Kontakt/portfolio: github.com/jeremichmielnicki-glitch  
