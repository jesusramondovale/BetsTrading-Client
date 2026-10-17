<#
.SYNOPSIS
  Compila Betrader para Flutter Web y lo copia a BetsTrading-Service (wwwroot/betrader).

.PARAMETER ServiceRoot
  Raíz del repo del servicio. Por defecto: C:\dev\BetsTrading-Service

.EXAMPLE
  .\scripts\publish_web.ps1
#>
param(
    [string]$ServiceRoot = "C:\dev\BetsTrading-Service"
)

$ErrorActionPreference = "Stop"

$ClientRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ClientRoot "pubspec.yaml"))) {
    throw "No se encontró pubspec.yaml en $ClientRoot"
}

$Dest = Join-Path $ServiceRoot "BetsTrading.API\wwwroot\betrader"
Write-Host "==> Cliente:  $ClientRoot"
Write-Host "==> Destino:  $Dest"
Write-Host "==> flutter build web --release --base-href /betrader/"

Push-Location $ClientRoot
try {
    flutter build web --release --base-href /betrader/
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build web falló con código $LASTEXITCODE"
    }

    $BuildWeb = Join-Path $ClientRoot "build\web"
    if (-not (Test-Path (Join-Path $BuildWeb "index.html"))) {
        throw "No existe build\web\index.html tras el build"
    }

    if (Test-Path $Dest) {
        Remove-Item -Recurse -Force $Dest
    }
    # Limpiar destino antiguo /app si existe
    $LegacyApp = Join-Path $ServiceRoot "BetsTrading.API\wwwroot\app"
    if (Test-Path $LegacyApp) {
        Remove-Item -Recurse -Force $LegacyApp
    }

    New-Item -ItemType Directory -Path $Dest -Force | Out-Null
    Copy-Item -Path (Join-Path $BuildWeb "*") -Destination $Dest -Recurse -Force

    # Si existe carpeta publish (dotnet publish), sincronizar también.
    $PublishDest = Join-Path $ServiceRoot "publish\wwwroot\betrader"
    if (Test-Path (Join-Path $ServiceRoot "publish\wwwroot")) {
        if (Test-Path $PublishDest) {
            Remove-Item -Recurse -Force $PublishDest
        }
        New-Item -ItemType Directory -Path $PublishDest -Force | Out-Null
        Copy-Item -Path (Join-Path $BuildWeb "*") -Destination $PublishDest -Recurse -Force
        Write-Host "También copiado a: $PublishDest"
    }

    Write-Host ""
    Write-Host "OK. Web copiada a:"
    Write-Host "  $Dest"
    Write-Host "URL esperada tras desplegar el servicio:"
    Write-Host "  https://api.betstrading.online/betrader/"
}
finally {
    Pop-Location
}
