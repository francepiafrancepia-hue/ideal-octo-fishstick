# Cleanup старите venv (интерактивно)

$oldVenvs = @(
    'C:\Users\User\Desktop\openinterpreter_env',
    'C:\Users\User\Desktop\Project\.venv',
    'C:\Users\User\Desktop\Project\.venv311',
    'C:\Users\User\OneDrive\Project\.venv'
)

foreach ($venv in $oldVenvs) {
    if (Test-Path $venv) {
        Write-Host ""
        Write-Host "Found: $venv" -ForegroundColor Yellow
        $size = (Get-ChildItem $venv -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "Size: {0:N2} MB" -f $size
        Write-Host "Delete? (yes/no/all)" -ForegroundColor Gray
        $confirm = Read-Host
        
        if ($confirm -eq "yes" -or $confirm -eq "all") {
            Remove-Item -Path $venv -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Deleted: $venv" -ForegroundColor Green
            if ($confirm -eq "all") { break }
        }
    }
}
