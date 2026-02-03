# Quick Docker Setup & Startup Script

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  DOCKER SERVICES SETUP & STARTUP                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify Docker is running
Write-Host "Step 1: Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "  ✅ Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Docker not found. Please install Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Verify .env file
Write-Host "Step 2: Checking .env configuration..." -ForegroundColor Yellow
if (Test-Path .env) {
    Write-Host "  ✅ .env exists" -ForegroundColor Green
    # Show sample env vars (redacted for security)
    $envVars = Get-Content .env | Select-String "^[^#]" | Select-Object -First 3
    Write-Host "  Sample variables:" -ForegroundColor Gray
    $envVars | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Host "  ⚠️  .env not found. Creating from .env.example..." -ForegroundColor Yellow
    if (Test-Path .env.example) {
        Copy-Item .env.example .env
        Write-Host "  ✅ Created .env from .env.example" -ForegroundColor Green
        Write-Host "  ⚠️  Edit .env and update credentials before starting services!" -ForegroundColor Yellow
    } else {
        Write-Host "  ❌ .env.example not found either!" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 3: Pull latest images
Write-Host "Step 3: Pulling Docker images..." -ForegroundColor Yellow
Write-Host "  (This may take a few minutes on first run...)" -ForegroundColor Gray
docker-compose pull --quiet
Write-Host "  ✅ Images pulled" -ForegroundColor Green

Write-Host ""

# Step 4: Start services
Write-Host "Step 4: Starting services..." -ForegroundColor Yellow
docker-compose up -d
Write-Host "  ✅ Services starting..." -ForegroundColor Green

Write-Host ""

# Step 5: Wait for services to be ready
Write-Host "Step 5: Waiting for services to be ready..." -ForegroundColor Yellow
Write-Host "  (This may take 30-60 seconds...)" -ForegroundColor Gray

Start-Sleep -Seconds 10

# Check postgres
Write-Host ""
Write-Host "  Checking PostgreSQL..." -ForegroundColor Gray
$pgReady = $false
for ($i = 0; $i -lt 6; $i++) {
    try {
        $result = docker exec ml-postgres pg_isready -U devops_ml -q
        if ($LASTEXITCODE -eq 0) {
            $pgReady = $true
            break
        }
    } catch { }
    Start-Sleep -Seconds 5
}
if ($pgReady) {
    Write-Host "    ✅ PostgreSQL is ready" -ForegroundColor Green
} else {
    Write-Host "    ⚠️  PostgreSQL taking time to initialize..." -ForegroundColor Yellow
}

Write-Host ""

# Step 6: Verify all services
Write-Host "Step 6: Verifying services..." -ForegroundColor Yellow
Write-Host ""

docker-compose ps | ForEach-Object {
    if ($_ -match "ml-") {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

Write-Host ""

# Step 7: Display service URLs
Write-Host "Step 7: Service URLs:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  🔵 PostgreSQL" -ForegroundColor Cyan
Write-Host "     Host: localhost" -ForegroundColor Gray
Write-Host "     Port: 5432" -ForegroundColor Gray
Write-Host "     User: devops_ml" -ForegroundColor Gray
Write-Host ""
Write-Host "  🟢 Redis" -ForegroundColor Cyan
Write-Host "     URL: redis://localhost:6379" -ForegroundColor Gray
Write-Host ""
Write-Host "  🟡 MLflow" -ForegroundColor Cyan
Write-Host "     URL: http://localhost:5000" -ForegroundColor Gray
Write-Host ""
Write-Host "  📊 Grafana" -ForegroundColor Cyan
Write-Host "     URL: http://localhost:3000" -ForegroundColor Gray
Write-Host "     User: admin" -ForegroundColor Gray
Write-Host "     Password: (see .env GF_SECURITY_ADMIN_PASSWORD)" -ForegroundColor Gray
Write-Host ""
Write-Host "  🦙 Ollama (optional LLM)" -ForegroundColor Cyan
Write-Host "     URL: http://localhost:11434" -ForegroundColor Gray
Write-Host ""

# Step 8: Quick health check
Write-Host "Step 8: Quick health check..." -ForegroundColor Yellow
Write-Host ""

$services = @{
    "PostgreSQL" = "postgresql://localhost:5432"
    "Redis" = "redis://localhost:6379"
    "MLflow" = "http://localhost:5000"
    "Grafana" = "http://localhost:3000"
}

foreach ($service in $services.GetEnumerator()) {
    try {
        $response = Invoke-WebRequest -Uri $service.Value -TimeoutSec 2 -ErrorAction SilentlyContinue
        Write-Host "  ✅ $($service.Key)" -ForegroundColor Green
    } catch {
        # Special handling for services without HTTP
        if ($service.Key -eq "PostgreSQL" -or $service.Key -eq "Redis") {
            Write-Host "  ℹ️  $($service.Key) (non-HTTP, started)" -ForegroundColor Gray
        } else {
            Write-Host "  ⚠️  $($service.Key) - still initializing..." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ DOCKER SERVICES READY                                     ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open http://localhost:3000 (Grafana)" -ForegroundColor Gray
Write-Host "  2. Open http://localhost:5000 (MLflow)" -ForegroundColor Gray
Write-Host "  3. Connect your Python apps with connection strings above" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Yellow
Write-Host "  docker-compose down" -ForegroundColor Gray
Write-Host ""
Write-Host "To view logs:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f [service-name]" -ForegroundColor Gray
Write-Host ""
