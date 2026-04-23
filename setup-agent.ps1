<#
.SYNOPSIS
    Еднократна настройка — създава папки, конвертира файлове и подготвя EXPORT_TEXT.

.DESCRIPTION
    Този скрипт прави следното:
    1. Създава целевите папки (crypto-arbitrage, loopholes-ideas, powershell-and-commands)
    2. Създава работните папки (INBOX_RAW, EXPORT_TEXT)
    3. Създава шаблонните файлове ако не съществуват
    4. Конвертира DOCX/ODT файлове от INBOX_RAW към Markdown в EXPORT_TEXT (чрез Pandoc или LibreOffice)
    5. Копира TXT/MD файлове директно в EXPORT_TEXT
    6. Добавя SOURCE_FILE хедъри към всеки експортиран файл

.NOTES
    Изисквания: Pandoc ИЛИ LibreOffice за конвертиране на DOCX/ODT файлове.
    Ако нямаш нито едно, TXT и MD файлове пак ще бъдат обработени.

.EXAMPLE
    # Изпълни от корена на проекта:
    .\setup-agent.ps1

    # Или с указан път до INBOX:
    .\setup-agent.ps1 -InboxPath "C:\Users\Me\Desktop\INBOX_RAW"
#>

param(
    [string]$InboxPath = "",
    [string]$ExportPath = "",
    [switch]$SkipConversion
)

# === RESOLVE PATHS ===
$ProjectRoot = $PSScriptRoot
if (-not $ProjectRoot) { $ProjectRoot = Get-Location }

# Default: use project-local folders; fallback to Desktop if -InboxPath given
if ($InboxPath -eq "") {
    $INBOX = Join-Path $ProjectRoot "INBOX_RAW"
} else {
    $INBOX = $InboxPath
}

if ($ExportPath -eq "") {
    $EXPORT = Join-Path $ProjectRoot "EXPORT_TEXT"
} else {
    $EXPORT = $ExportPath
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Windsurf Cascade Agent — Setup Script"     -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Project Root : $ProjectRoot"
Write-Host "  INBOX_RAW    : $INBOX"
Write-Host "  EXPORT_TEXT  : $EXPORT"
Write-Host ""

# === 1) CREATE DIRECTORIES ===
Write-Host "[1/4] Създаване на папки..." -ForegroundColor Yellow

$directories = @(
    $INBOX,
    $EXPORT,
    (Join-Path $ProjectRoot "crypto-arbitrage"),
    (Join-Path $ProjectRoot "loopholes-ideas"),
    (Join-Path $ProjectRoot "powershell-and-commands")
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "  + Създадена: $dir" -ForegroundColor Green
    } else {
        Write-Host "  = Съществува: $dir" -ForegroundColor DarkGray
    }
}

# === 2) CREATE TEMPLATE FILES ===
Write-Host "[2/4] Проверка на шаблонни файлове..." -ForegroundColor Yellow

$targetFiles = @(
    "crypto-arbitrage\00_README_обхват-и-правила.md",
    "crypto-arbitrage\01_Примери_конкретни-сметки.md",
    "crypto-arbitrage\02_Стратегии_дневна-доходност.md",
    "crypto-arbitrage\03_Код_скенери-и-изпълнение.md",
    "crypto-arbitrage\04_Такси_рискове_ограничения.md",
    "crypto-arbitrage\05_Проверка_валидиране.md",
    "loopholes-ideas\01_Идеи_за-доразвиване.md",
    "loopholes-ideas\02_Kitchen-secrets_наблюдения.md",
    "loopholes-ideas\03_Изисквания-за-инфраструктура.md",
    "powershell-and-commands\01_PowerShell_команди_каталог.md",
    "powershell-and-commands\02_Скриптове_готови-блокове.ps1",
    "powershell-and-commands\03_Чийтшит_едноредови-команди.md"
)

foreach ($rel in $targetFiles) {
    $full = Join-Path $ProjectRoot $rel
    if (!(Test-Path $full)) {
        New-Item -ItemType File -Force -Path $full | Out-Null
        Write-Host "  + Създаден: $rel" -ForegroundColor Green
    } else {
        Write-Host "  = Съществува: $rel" -ForegroundColor DarkGray
    }
}

# === 3) DETECT CONVERSION TOOL ===
Write-Host "[3/4] Откриване на инструмент за конвертиране..." -ForegroundColor Yellow

$converter = "none"

# Check for Pandoc
try {
    $null = Get-Command pandoc -ErrorAction Stop
    $converter = "pandoc"
    Write-Host "  Открит: Pandoc" -ForegroundColor Green
} catch {
    # Check for LibreOffice
    $soffice = @(
        "C:\Program Files\LibreOffice\program\soffice.exe",
        "C:\Program Files (x86)\LibreOffice\program\soffice.exe",
        "/usr/bin/soffice",
        "/usr/bin/libreoffice"
    )
    foreach ($s in $soffice) {
        if (Test-Path $s) {
            $converter = "libreoffice"
            $sofficePath = $s
            Write-Host "  Открит: LibreOffice ($s)" -ForegroundColor Green
            break
        }
    }
    if ($converter -eq "none") {
        Write-Host "  ! Няма Pandoc или LibreOffice — DOCX/ODT файлове НЯМА да бъдат конвертирани." -ForegroundColor Red
        Write-Host "    TXT и MD файлове пак ще бъдат обработени." -ForegroundColor DarkYellow
    }
}

# === 4) CONVERT & EXPORT ===
if ($SkipConversion) {
    Write-Host "[4/4] Конвертирането е пропуснато (-SkipConversion)" -ForegroundColor Yellow
} else {
    Write-Host "[4/4] Конвертиране и експортиране..." -ForegroundColor Yellow

    $files = Get-ChildItem $INBOX -Recurse -File -ErrorAction SilentlyContinue
    if ($null -eq $files -or $files.Count -eq 0) {
        Write-Host "  ! INBOX_RAW е празна. Копирай входни файлове и пусни скрипта отново." -ForegroundColor DarkYellow
    } else {
        $converted = 0
        $copied = 0
        $skipped = 0

        foreach ($file in $files) {
            $ext = $file.Extension.ToLower()
            $base = $file.BaseName
            $out = Join-Path $EXPORT ($base + ".md")

            # Skip .gitkeep
            if ($file.Name -eq ".gitkeep") { continue }

            if ($ext -in ".docx", ".odt") {
                if ($converter -eq "pandoc") {
                    $pandocErr = $null
                    & pandoc $file.FullName -t markdown -o $out 2>&1 | ForEach-Object {
                        if ($_ -is [System.Management.Automation.ErrorRecord]) { $pandocErr = $_.ToString() }
                    }
                    if ($pandocErr) {
                        Write-Host "  ! Pandoc грешка за $($file.Name): $pandocErr" -ForegroundColor Red
                        $skipped++
                        continue
                    }
                    $converted++
                } elseif ($converter -eq "libreoffice") {
                    $loErr = $null
                    & $sofficePath --headless --convert-to "txt:Text" --outdir $EXPORT $file.FullName 2>&1 | ForEach-Object {
                        if ($_ -is [System.Management.Automation.ErrorRecord]) { $loErr = $_.ToString() }
                    }
                    if ($loErr) {
                        Write-Host "  ! LibreOffice грешка за $($file.Name): $loErr" -ForegroundColor Red
                        $skipped++
                        continue
                    }
                    $txtOut = Join-Path $EXPORT ($base + ".txt")
                    if (Test-Path $txtOut) {
                        Move-Item $txtOut $out -Force
                    }
                    $converted++
                } else {
                    Write-Host "  ! Пропуснат (няма конвертор): $($file.Name)" -ForegroundColor Red
                    $skipped++
                    continue
                }
            } elseif ($ext -in ".txt", ".md") {
                Copy-Item $file.FullName $out -Force
                $copied++
            } else {
                $skipped++
                continue
            }

            # Add SOURCE header
            if (Test-Path $out) {
                $nl = [System.Environment]::NewLine
                $header = "# SOURCE_FILE: $($file.Name)${nl}# SOURCE_PATH: $($file.FullName)${nl}${nl}"
                $content = Get-Content $out -Raw -ErrorAction SilentlyContinue
                if ($null -eq $content) { $content = "" }
                try {
                    Set-Content -Path $out -Value ($header + $content) -Encoding UTF8 -ErrorAction Stop
                } catch {
                    Write-Host "  ! Грешка при запис на $out : $_" -ForegroundColor Red
                }
            }
        }

        Write-Host ""
        Write-Host "  Резултат:" -ForegroundColor Cyan
        Write-Host "    Конвертирани (DOCX/ODT → MD): $converted"
        Write-Host "    Копирани (TXT/MD):            $copied"
        Write-Host "    Пропуснати:                   $skipped"
    }
}

# === DONE ===
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  ГОТОВО! Следваща стъпка:"                   -ForegroundColor Green
Write-Host "  1. Отвори Windsurf/Cascade"                 -ForegroundColor Green
Write-Host "  2. Отвори тази папка като workspace"        -ForegroundColor Green
Write-Host "  3. Агентът ще прочете .windsurfrules"       -ForegroundColor Green
Write-Host "     и ще обработи EXPORT_TEXT/"              -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
