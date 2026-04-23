---
trigger: glob
globs: ["EXPORT_TEXT/**/*.md", "crypto-arbitrage/**/*.md", "loopholes-ideas/**/*.md", "powershell-and-commands/**/*"]
description: Правила за обработка на файлове — класификация и качество
---

# File Processing Rules

<input_handling>
- Винаги чети файловете с UTF-8 encoding
- Търси "# SOURCE_FILE:" хедъри за проследяване на произход
- Един входен файл може да съдържа множество теми — раздели ги
</input_handling>

<output_handling>
- САМО добавяй към целеви файлове — НЕ изтривай съществуващо съдържание
- Поддържай последователен формат с record_template от .windsurfrules
- При дублиращи се записи: обедини и изброй всички източници
</output_handling>

<error_handling>
- Ако файл не може да се прочете: логни грешката и продължи
- Ако съдържание не пасва на нито една категория: добави в loopholes-ideas/01_Идеи_за-доразвиване.md
- Ако липсват числа/дати: отбележи "липсва" (НЕ измисляй)
</error_handling>
