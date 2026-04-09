---
trigger: always_on
description: Правила за кодиране — стил, формат и конвенции
---

# Coding Standards

<naming_conventions>
- Файлове: snake_case за скриптове, PascalCase за модули
- Променливи (PowerShell): $PascalCase
- Променливи (Python): snake_case
- Константи: UPPER_SNAKE_CASE
</naming_conventions>

<code_style>
- Encoding: UTF-8 навсякъде
- Нови редове: LF (Unix) за .md, .py; CRLF за .ps1
- Индентация: 4 spaces (без табулации)
- Максимална дължина на ред: 120 символа
- Кодови блокове: ВИНАГИ с language tag (```powershell, ```python, ```bash)
</code_style>

<documentation>
- Всеки скрипт: кратък коментар отгоре (какво прави)
- Всеки .md файл: H1 заглавие + кратко описание
- Без излишни коментари — код трябва да е самообяснителен
</documentation>
