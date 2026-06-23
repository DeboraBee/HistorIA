# Script para executar testes automatizados na aplicação HistorIA

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TESTE AUTOMATIZADO                      ║" -ForegroundColor Cyan
Write-Host "║                      HistorIA v1.0                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = $scriptPath

# Função para instalar dependências
function Install-Dependencies {
    param(
        [string]$ServiceName,
        [string]$ServicePath
    )
    
    Write-Host "📦 Instalando dependências para $ServiceName..." -ForegroundColor Yellow
    
    $requirementsPath = Join-Path $ServicePath "requirements.txt"
    if (Test-Path $requirementsPath) {
        & pip install -q -r $requirementsPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Dependências de $ServiceName instaladas" -ForegroundColor Green
        } else {
            Write-Host "❌ Erro ao instalar dependências de $ServiceName" -ForegroundColor Red
        }
    }
}

# Função para executar testes
function Run-ServiceTests {
    param(
        [string]$ServiceName,
        [string]$ServicePath
    )
    
    Write-Host ""
    Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "Testando: $ServiceName" -ForegroundColor Magenta
    Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
    
    Push-Location $ServicePath
    
    # Executa pytest
    & python -m pytest -v --tb=short test_main.py 2>&1 | Tee-Object -Variable testOutput
    $testResult = $LASTEXITCODE
    
    Pop-Location
    
    if ($testResult -eq 0) {
        Write-Host "✅ $ServiceName: PASSOU" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $ServiceName: FALHOU" -ForegroundColor Red
        return $false
    }
}

# Define os serviços a testar
$services = @(
    @{ Name = "Alunos"; Path = "$appRoot\services\alunos" },
    @{ Name = "Exercícios"; Path = "$appRoot\services\exercicios" },
    @{ Name = "Conteúdos"; Path = "$appRoot\services\conteudos" },
    @{ Name = "Trilhas"; Path = "$appRoot\services\trilhas" }
)

# Instala dependências
Write-Host "🔧 Instalando dependências de todos os serviços..." -ForegroundColor Cyan
Write-Host ""

foreach ($service in $services) {
    Install-Dependencies -ServiceName $service.Name -ServicePath $service.Path
}

# Executa testes
$passedCount = 0
$failedCount = 0
$results = @()

foreach ($service in $services) {
    if (Run-ServiceTests -ServiceName $service.Name -ServicePath $service.Path) {
        $passedCount++
        $results += "✅ $($service.Name)"
    } else {
        $failedCount++
        $results += "❌ $($service.Name)"
    }
}

# Relatório final
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   RELATÓRIO FINAL                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$totalServices = $services.Count
Write-Host "Total de Serviços: $totalServices"
Write-Host "✅ Passaram: $passedCount" -ForegroundColor Green
Write-Host "❌ Falharam: $failedCount" -ForegroundColor Red
Write-Host ""

Write-Host "Detalhes:" -ForegroundColor Yellow
foreach ($result in $results) {
    Write-Host $result
}

Write-Host ""

if ($failedCount -eq 0) {
    Write-Host "🎉 Todos os testes passaram com sucesso!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Alguns testes falharam. Verifique os detalhes acima." -ForegroundColor Red
    exit 1
}
