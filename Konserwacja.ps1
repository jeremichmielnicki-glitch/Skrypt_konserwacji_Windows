# =====================================================================
# Skrypt automatycznej konserwacji systemu windows za pomocą PowerShell
# Przed uruchomieniem skryptu przeczytaj plik README.md
# Wersja 1.1   30.08.2026
# Autorem skryptu jest Jeremiasz Chmielnicki
# =====================================================================

# 1. Sprawdzenie uprawnień Administratora
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Ustawienie ścieżki pulpitu dla pliku raportu
$desktopPath = [Environment]::GetFolderPath("Desktop")
$dateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$logFile = Join-Path -Path $desktopPath -ChildPath "Raport_Konserwacji_$dateStamp.txt"

# Funkcja pomocnicza do zapisu w logu i wyświetlania kolorowych komunikatów
function Write-Log {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timeStamp] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding utf8
    Write-Host $Message -ForegroundColor $Color
}

# Nagłówek raportu
"====================================================" | Out-File -FilePath $logFile -Encoding utf8
"  RAPORT Z AUTOMATYCZNEJ KONSERWACJI SYSTEMU WINDOWS " | Out-File -FilePath $logFile -Append -Encoding utf8
"  Data rozpoczęcia: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $logFile -Append -Encoding utf8
"====================================================" | Out-File -FilePath $logFile -Append -Encoding utf8
"" | Out-File -FilePath $logFile -Append -Encoding utf8

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  AUTOMATYCZNA KONSERWACJA SYSTEMU WINDOWS" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Trwa wykonywanie zadań. Pasek postępu u góry okna.`n" -ForegroundColor Gray

$totalSteps = 8
$currentStep = 0

# --- KROK 1: Czyszczenie Temp i Kosza ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Czyszczenie plików tymczasowych (%TEMP%) i Kosza" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[1/8] Czyszczenie folderów TEMP oraz Kosza..." -Color Yellow

try {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log " -> Temp i Kosz zostały oczyszczone." -Color Green
} catch {
    Write-Log " -> Pominięto pliki będące w użyciu." -Color DarkYellow
}

# --- KROK 2: Czyszczenie magazynu WinSxS ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Usuwanie starych aktualizacji (WinSxS)" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[2/8] Usuwanie starych kopii aktualizacji Windows (WinSxS)..." -Color Yellow

dism.exe /Online /Cleanup-Image /StartComponentCleanup
if ($LASTEXITCODE -eq 0) {
    Write-Log " -> Czyszczenie WinSxS zakończone sukcesem." -Color Green
} else {
    Write-Log " -> DISM StartComponentCleanup kod: $LASTEXITCODE" -Color DarkYellow
}

# --- KROK 3: Czyszczenie DNS ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Czyszczenie pamięci podręcznej DNS" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[3/8] Czyszczenie pamięci podręcznej DNS..." -Color Yellow
try {
    Clear-DnsClientCache
    Write-Log " -> Pamięć podręczna DNS wyczyszczona." -Color Green
} catch {
    ipconfig /flushdns | Out-Null
    Write-Log " -> Wyczyszczono DNS za pomocą ipconfig." -Color Green
}

# --- KROK 4: Naprawa magazynu komponentów DISM ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Naprawa obrazu systemu DISM" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[4/8] Naprawa obrazu systemu Windows (DISM RestoreHealth)..." -Color Yellow

dism.exe /Online /Cleanup-Image /RestoreHealth
if ($LASTEXITCODE -eq 0) {
    Write-Log " -> Obraz systemu został pomyślnie zweryfikowany/naprawiony." -Color Green
} else {
    Write-Log " -> DISM zgłosił problemy (Kod wyjścia: $LASTEXITCODE)." -Color DarkYellow
}

# --- KROK 5: Skanowanie SFC ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Skanowanie i naprawa plików SFC" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[5/8] Skanowanie spójności plików systemowych (SFC /scannow)..." -Color Yellow

sfc.exe /scannow
if ($LASTEXITCODE -eq 0) {
    Write-Log " -> Skanowanie SFC zakończone sukcesem." -Color Green
} else {
    Write-Log " -> SFC zakończył działanie z kodem: $LASTEXITCODE" -Color DarkYellow
}

# --- KROK 6: Skanowanie CHKDSK ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Skanowanie dysków CHKDSK" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[6/8] Skanowanie dysków pod kątem błędów (CHKDSK /scan)..." -Color Yellow

$drives = Get-Volume | Where-Object { $_.DriveLetter -and $_.FileSystem -eq "NTFS" }
foreach ($drive in $drives) {
    $letter = $drive.DriveLetter
    Write-Log " -> Skanowanie partycji ${letter}: ..." -Color Gray
    
    chkdsk.exe "$($letter):" /scan
    if ($LASTEXITCODE -eq 0) {
        Write-Log " -> Dysk ${letter}: brak błędów struktury plików." -Color Green
    } else {
        Write-Log " -> Dysk ${letter}: CHKDSK zwrócił kod $LASTEXITCODE." -Color DarkYellow
    }
}

# --- KROK 7: Optymalizacja dysków (TRIM / Defrag) ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Krok $currentStep/${totalSteps}: Optymalizacja dysków (TRIM / Defrag)" -PercentComplete (($currentStep / $totalSteps) * 100)
Write-Log "[7/8] Optymalizacja dysków (TRIM dla SSD, Defragmentacja dla HDD)..." -Color Yellow

foreach ($drive in $drives) {
    $letter = $drive.DriveLetter
    Write-Log " -> Optymalizacja partycji ${letter}: ..." -Color Gray
    try {
        Optimize-Volume -DriveLetter $letter -Defrag -ReTrim -ErrorAction Stop
        Write-Log " -> Dysk ${letter}: optymalizacja zakończona." -Color Green
    } catch {
        defrag "$($letter):" /O | Out-Null
        Write-Log " -> Dysk ${letter}: wykonano alternatywnie przez defrag.exe." -Color Green
    }
}

# --- KROK 8: Zakończenie i podsumowanie ---
$currentStep++
Write-Progress -Activity "Konserwacja Systemu" -Status "Zakończono!" -PercentComplete 100
Write-Log "[8/8] Podsumowanie i zapis raportu..." -Color Yellow

Write-Log "`n====================================================" -Color Cyan
Write-Log " KONSERWACJA ZAKOŃCZONA!" -Color Green
Write-Log " Pełny raport został zapisany na Pulpicie:" -Color White
Write-Log " $logFile" -Color Cyan
Write-Log "====================================================" -Color Cyan

# Ukrycie paska postępu
Write-Progress -Activity "Konserwacja Systemu" -Completed

# Interactive Odliczanie do restartu
Write-Host "`n[!] Komputer zostanie zrestartowany za 15 sekund." -ForegroundColor Red
Write-Host "Naciśnij DOWOLNY KLAWISZ, aby ANULOWAĆ automatyczny restart...`n" -ForegroundColor Yellow

$cancelRestart = $false

for ($i = 15; $i -gt 0; $i--) {
    Write-Host -NoNewline "`rRestart za $i sek. (Naciśnij klawisz, aby anulować)... "
    if ([Console]::KeyAvailable) {
        [Console]::ReadKey($true) | Out-Null
        $cancelRestart = $true
        break
    }
    Start-Sleep -Seconds 1
}

if ($cancelRestart) {
    Write-Host "`n`n[OK] Anulowano ponowne uruchomienie komputera." -ForegroundColor Green
    Write-Log " -> Ponowne uruchomienie systemu zostało anulowane przez użytkownika." -Color Yellow
} else {
    Write-Host "`n`n[!] Inicjowanie ponownego uruchomienia..." -ForegroundColor Red
    shutdown.exe /r /t 0 /c "Automatyczna konserwacja systemu została zakończona."
}
